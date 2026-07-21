let recipe = import "recipe-lib.ncl" in

# A separate rootfs branch for the graphical (eventually GNOME) QEMU guest, so
# the plain rootfs/erofs_rootfs path stays small and untouched. For now it is
# the base rootfs plus the accel-only graphics stack (libdrm + Mesa/virgl) and
# the kmscube DRM/EGL smoke test. It will grow toward a full GNOME session; see
# 0629_gnome.md for the direction. Boot it with tools/bobr-run-qemu-gnome.sh.
fun pkgs =>
  # System weston config + launcher:
  #  - /etc/xdg/weston/weston.ini pins the cursor theme and a smaller 16px
  #    cursor (weston's default is 32);
  #  - /usr/bin/weston-start brings up Weston from a serial console (ttySx):
  #    sets XDG_RUNTIME_DIR, starts seatd if needed, runs weston via the seatd
  #    libseat backend. Extra args are forwarded to weston.
  let weston_launcher_script = m%"
    #!/usr/bin/env bash
    # Launch Weston from a serial console (ttySx). Usage: weston-start [WESTON_ARG...]
    set -eu

    export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/xdg}"
    mkdir -p "$XDG_RUNTIME_DIR"
    chmod 0700 "$XDG_RUNTIME_DIR"

    # seatd hands out the DRM/input devices without logind; start it if the
    # socket is not already there, then wait for it to come up.
    if [ ! -S /run/seatd.sock ]; then
      seatd &
      for _ in $(seq 1 50); do
        [ -S /run/seatd.sock ] && break
        sleep 0.1
      done
    fi

    export LIBSEAT_BACKEND=seatd
    exec weston --backend=drm "$@"
  "%
  in

  let weston_config_files = {
    name = "weston-config-files",
    tag = "Tree",
    config = {
      tree = {
        entries = [
          { type = "dir", path = "etc" },
          { type = "dir", path = "etc/xdg" },
          { type = "dir", path = "etc/xdg/weston" },
          {
            type = "file",
            path = "etc/xdg/weston/weston.ini",
            text = "[shell]\ncursor-theme=Bibata-Modern-Classic\ncursor-size=16\n",
            executable = false,
          },
          { type = "dir", path = "usr" },
          { type = "dir", path = "usr/bin" },
          {
            type = "file",
            path = "usr/bin/weston-start",
            text = weston_launcher_script,
            executable = true,
          },
        ],
      },
    },
    inputs = {},
  }
  in

  let weston_config = {
    name = "weston-config",
    tag = "FsTreeImport",
    config = {
      install = {
        rules = [
          recipe.install.fs_tree_root_default_rule,
        ],
      },
    },
    inputs = {
      input = weston_config_files,
    },
  }
  in

  # The image contents as a runtime closure: base_filesystem + the runtime
  # closure of these roots. The whole GTK/GNOME library stack below the
  # top-level apps is pulled automatically from the recipes' deps.runtime, so
  # the former hand-curated flat list is gone. Roots are only the things wanted
  # for their own sake (not reachable as a runtime dep of another root): the
  # base rootfs, the graphics/session runtime-files overlays, the accel-graphics
  # + Wayland stack, fonts/cursors (pure data), and the top-level GNOME apps.
  # "Invisible" deps that ldd cannot see (icon themes, base typelibs, the
  # GSettings dconf backend, the SVG loader) now live in the owning recipes'
  # deps.runtime: gtk4, gjs, gdm, gnome-shell.
  let gnome_rootfs_contents = {
    name = "gnome-rootfs-contents",
    tag = "RootfsClosure",
    config = {},
    inputs =
      recipe.numbered_inputs [
        pkgs.rootfs,
        # Graphics-only runtime files (tty1 autologin, weston user service +
        # graphical-session wiring) and the system weston config/launcher.
        pkgs.system_runtime_files_gnome,
        weston_config,
        # Accel graphics + Wayland session stack.
        pkgs.mesa,
        pkgs.vulkan_loader,
        pkgs.vulkan_tools,
        pkgs.kmscube,
        pkgs.weston,
        pkgs.seatd,
        pkgs.xkeyboard_config,
        # Fonts + cursor theme (pure data, not reachable via link deps).
        pkgs.dejavu,
        pkgs.bibata_cursors,
        # Top-level GNOME toolkit/session/apps; the whole GNOME library stack is
        # their runtime closure.
        pkgs.gtk4,
        pkgs.gnome_shell,
        pkgs.gnome_session,
        pkgs.gdm,
        pkgs.gnome_settings_daemon,
        pkgs.gnome_control_center,
      ],
  }
  in

  # Finalize: regenerate the aggregate caches over the merged tree. These index
  # files are contributed by many packages and cannot be regenerated on the
  # read-only /usr at runtime, so they are baked here at build time (as
  # rpm-ostree/mkosi do). The build runs with the merged tree as a read-write
  # overlay root and captures ONLY the generated caches as an additive layer
  # (SandboxInstall) -- nothing is removed or modified. The generator tools come
  # from the tree itself, so there is no parallel cache env and no version skew.
  # (ld.so.cache is absent from the tree -- glibc no longer ships a partial one;
  # 10-eth-dhcp.network is masked via system-runtime-files-gnome, not deleted.)
  let gnome_finalize = {
    name = "gnome-finalize",
    tag = "SandboxInstall",
    config = {
      script_config = {},
      steps = [
        {
          name = "finalize_caches",
          run_as = "root",
          cwd = "/",
          argv = [
            "/bin/bash",
            "-ec",
            m%"
              # Complete ld.so.cache over the whole tree (glibc ships none now).
              # -X: write only the cache, do not recreate the version symlinks
              # packages already installed. -i: do not write the auxiliary cache
              # (/var/cache/ldconfig/aux-cache) -- its per-library dev/inode/ctime
              # keys are non-reproducible across machines, and it is dead weight
              # on a read-only image (ldconfig never re-runs to use it). Matches
              # what debootstrap/OpenEmbedded drop for reproducible read-only rootfs.
              ldconfig -X -i

              # GSettings schemas -> gschemas.compiled
              if [ -d /usr/share/glib-2.0/schemas ]; then
                glib-compile-schemas /usr/share/glib-2.0/schemas
              fi

              # gdk-pixbuf loaders.cache. Querying the loaders at their runtime
              # path means the SVG loader (librsvg) resolves librsvg-2.so on the
              # normal /usr/lib and the cache records /usr paths directly -- no
              # LD_LIBRARY_PATH and no $out prefix rewriting needed anymore.
              gdkdir=/usr/lib/gdk-pixbuf-2.0/2.10.0
              if [ -d "$gdkdir/loaders" ]; then
                gdk-pixbuf-query-loaders > "$gdkdir/loaders.cache"
              fi

              # GIO modules cache
              if [ -d /usr/lib/gio/modules ]; then
                gio-querymodules /usr/lib/gio/modules
              fi

              # Icon theme caches
              for theme in Adwaita hicolor; do
                if [ -d "/usr/share/icons/$theme" ]; then
                  gtk4-update-icon-cache -qtf "/usr/share/icons/$theme"
                fi
              done
            "%,
          ],
        },
      ],
    },
    inputs = {
      _rootfs = gnome_rootfs_contents,
    },
  }
  in

  # The final GNOME rootfs = the merged contents plus the finalize cache layer.
  let gnome_rootfs = {
    name = "gnome-rootfs",
    tag = "TreeMerge",
    config = {},
    inputs =
      recipe.numbered_inputs [
        gnome_rootfs_contents,
        gnome_finalize,
      ],
  }
  in

  let gnome_erofs_rootfs =
    recipe.erofs_image
      pkgs
      {
        name = "gnome-erofs-rootfs",
        tree = gnome_rootfs,
      }
  in

  {
    include [
      gnome_rootfs,
      gnome_erofs_rootfs,
    ],
  }
