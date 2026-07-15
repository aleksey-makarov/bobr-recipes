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

  let gnome_rootfs_contents = {
    name = "gnome-rootfs-contents",
    tag = "TreeMerge",
    config = {},
    inputs =
      recipe.numbered_inputs [
        pkgs.rootfs,
        # Graphics-only runtime files (tty1 autologin, weston user service +
        # graphical-session wiring); kept out of the plain rootfs.
        pkgs.system_runtime_files_gnome,
        pkgs.libdrm,
        pkgs.mesa,
        pkgs.vulkan_loader,
        pkgs.vulkan_tools,
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
        # GNOME/GTK4 library stack (step 6a). Runtime artifacts only: glib_gen1
        # is a build-only intermediate (its libs are identical to glib's).
        pkgs.pcre2,
        pkgs.libxml2,
        pkgs.libjpeg_turbo,
        pkgs.libtiff,
        pkgs.glib,
        pkgs.gobject_introspection,
        pkgs.graphene,
        pkgs.fribidi,
        pkgs.harfbuzz,
        pkgs.pango,
        pkgs.libepoxy,
        pkgs.shared_mime_info,
        pkgs.gdk_pixbuf,
        pkgs.gtk4,
        pkgs.hicolor_icon_theme,
        pkgs.adwaita_icon_theme,
        # 6b (mutter deps so far)
        pkgs.json_glib,
        pkgs.gsettings_desktop_schemas,
        pkgs.lcms2,
        pkgs.sqlite,
        pkgs.colord,
        pkgs.libusb,
        pkgs.libgusb,
        pkgs.libgudev,
        pkgs.libseccomp,
        pkgs.glycin,
        # 6b: mutter (Wayland compositor) and its remaining new runtime deps.
        pkgs.at_spi2_core,
        pkgs.libei,
        pkgs.mutter,
        # 6c: gnome-shell and its runtime closure (beyond the base rootfs, which
        # already carries dbus/expat/libffi/linux-pam/util-linux/zlib/glib/
        # systemd, and beyond the GNOME/GTK4 stack listed above).
        #  - gjs + mozjs (+ icu): the JS engine the shell runs on
        #  - gcr stack: libgcrypt (+libgpg-error), p11-kit (+libtasn1)
        #  - gnome-desktop (+iso-codes)
        #  - polkit (+duktape): the in-session authentication agent
        #  - evolution-data-server + its chain (libsoup/libpsl/nghttp2, libical,
        #    libsecret, nspr, nss): the shell's clock/calendar backend
        pkgs.icu,
        pkgs.mozjs,
        pkgs.gjs,
        pkgs.libgpg_error,
        pkgs.libgcrypt,
        pkgs.libtasn1,
        pkgs.p11_kit,
        pkgs.gcr,
        pkgs.iso_codes,
        pkgs.gnome_desktop,
        pkgs.duktape,
        pkgs.polkit,
        pkgs.nghttp2,
        pkgs.libpsl,
        pkgs.libsoup,
        pkgs.libical,
        pkgs.libsecret,
        pkgs.nspr,
        pkgs.nss,
        pkgs.evolution_data_server,
        #  - libpulse (+libsndfile) for the shell's gvc volume control
        pkgs.libsndfile,
        pkgs.pulseaudio,
        #  - GI typelibs gnome-shell imports at startup that ldd cannot see:
        #    AccountsService, UPowerGlib, IBus, Gdm. dconf is the GSettings
        #    backend and gdm's session launcher.
        pkgs.accountsservice,
        pkgs.upower,
        pkgs.ibus,
        pkgs.dconf,
        pkgs.gdm,
        #  - typelibs gnome-shell imports unconditionally (misc/dependencies.js):
        #    Geoclue, GWeather, Rsvg. geocode-glib + gweather-locations are the
        #    libgweather runtime closure (the world locations database).
        pkgs.geoclue,
        pkgs.geocode_glib,
        pkgs.gweather_locations,
        pkgs.libgweather,
        pkgs.librsvg,
        #  - gnome-settings-daemon installs the org.gnome.settings-daemon.*
        #    GSettings schemas gnome-shell looks up at startup, and runs as a
        #    session service. Its runtime closure: NetworkManager (libnm) +
        #    libndp, libcanberra (+ libvorbis/libogg), libnotify, alsa-lib.
        pkgs.networkmanager,
        pkgs.libndp,
        pkgs.libnma,
        pkgs.libcanberra,
        pkgs.libvorbis,
        pkgs.libogg,
        pkgs.libnotify,
        pkgs.alsa_lib,
        pkgs.gnome_settings_daemon,
        pkgs.gnome_shell,
      ],
  }
  in

  # Build env holding the aggregate-cache generators (glib-compile-schemas and
  # gio-querymodules from glib, gdk-pixbuf-query-loaders from gdk-pixbuf,
  # gtk4-update-icon-cache from gtk4) plus a shell/coreutils.
  let gnome_rootfs_cache_env = {
    name = "gnome-rootfs-cache-env",
    tag = "RootfsClosure",
    config = {},
    inputs = {
      gtk4 = pkgs.gtk4,
      glib = pkgs.glib,
      gdk_pixbuf = pkgs.gdk_pixbuf,
      bash = pkgs.bash,
      coreutils = pkgs.coreutils,
      sed = pkgs.sed,
    },
  }
  in

  # Finalize the merged tree with the aggregate GNOME caches. These index files
  # contributed by many packages and cannot be regenerated on the read-only /usr
  # at runtime, so they are baked here at build time (as rpm-ostree/mkosi do).
  let gnome_rootfs = {
    name = "gnome-rootfs",
    tag = "SandboxBuildRootfs",
    config = {
      steps = [
        {
          name = "finalize_caches",
          run_as = "root",
          cwd = "@{out}",
          argv = [
            "/bin/bash",
            "-ec",
            m%"
              out="$BOBR_OUT_DIR"
              cp -a "$BOBR_INPUTS_DIR/_tree/." "$out/"

              # GSettings schemas -> gschemas.compiled
              if [ -d "$out/usr/share/glib-2.0/schemas" ]; then
                glib-compile-schemas "$out/usr/share/glib-2.0/schemas"
              fi

              # gdk-pixbuf loaders.cache. query-loaders dlopens each loader to
              # read its format info; the SVG loader (librsvg) pulls in
              # librsvg-2.so and its deps, which live in the rootfs being built,
              # not in this cache env -- so LD_LIBRARY_PATH points the loader at
              # $out/usr/lib, otherwise dlopen fails and the SVG loader is
              # silently dropped (blank symbolic icons everywhere). The tool
              # writes absolute loader paths; strip the build-time $out prefix so
              # they are the runtime /usr paths.
              gdkdir="$out/usr/lib/gdk-pixbuf-2.0/2.10.0"
              if [ -d "$gdkdir/loaders" ]; then
                GDK_PIXBUF_MODULEDIR="$gdkdir/loaders" \
                LD_LIBRARY_PATH="$out/usr/lib" \
                  gdk-pixbuf-query-loaders > "$gdkdir/loaders.cache"
                sed -i "s|$out||g" "$gdkdir/loaders.cache"
              fi

              # GIO modules cache (stores basenames, no prefix to strip)
              if [ -d "$out/usr/lib/gio/modules" ]; then
                gio-querymodules "$out/usr/lib/gio/modules"
              fi

              # Icon theme caches
              for theme in Adwaita hicolor; do
                if [ -d "$out/usr/share/icons/$theme" ]; then
                  gtk4-update-icon-cache -qtf "$out/usr/share/icons/$theme"
                fi
              done
            "%,
          ],
        },
      ],
    },
    inputs = {
      _rootfs = gnome_rootfs_cache_env,
      _tree = gnome_rootfs_contents,
    },
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
