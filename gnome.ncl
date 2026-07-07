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

  let gnome_rootfs = {
    name = "gnome-rootfs",
    tag = "TreeMerge",
    config = {},
    inputs =
      recipe.numbered_inputs [
        pkgs.rootfs,
        pkgs.libdrm,
        pkgs.mesa,
        pkgs.kmscube,
        # Wayland session stack (step 3: Weston via seatd).
        pkgs.libpng,
        pkgs.pixman,
        pkgs.freetype,
        pkgs.fontconfig,
        pkgs.cairo,
        pkgs.dejavu,
        pkgs.wayland,
        pkgs.libevdev,
        pkgs.mtdev,
        pkgs.libinput,
        pkgs.xkeyboard_config,
        pkgs.libxkbcommon,
        pkgs.seatd,
        pkgs.libdisplay_info,
        pkgs.bibata_cursors,
        pkgs.weston,
        weston_config,
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
