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
        #  - Bluetooth: gnome-shell loads its quick-settings indicator when the
        #    GnomeBluetooth-3.0 typelib is present (runtime pkg.checkSymbol).
        #    gnome-bluetooth pulls in libadwaita (+ its AppStream/libyaml/
        #    libxmlb/curl closure) and gsound.
        pkgs.libyaml,
        pkgs.libxmlb,
        pkgs.curl,
        pkgs.appstream,
        pkgs.libadwaita,
        pkgs.gsound,
        pkgs.gnome_bluetooth,
        pkgs.gnome_shell,
        #  - gnome-session: the session manager. It registers
        #    org.gnome.SessionManager, seeds the D-Bus/systemd activation
        #    environment, and drives the systemd-managed session
        #    (gnome-session@gnome.target -> org.gnome.Shell@user.service +
        #    gnome-session-services.target). gdm launches it via the
        #    wayland-sessions/gnome.desktop it ships (Exec=gnome-session).
        pkgs.gnome_session,
        #  - gnome-control-center (the Settings app) and the runtime closure of
        #    its panels beyond what the shell already pulls in: libgtop (Usage),
        #    libpwquality (Users), colord-gtk (Color), libwacom (Wacom), tecla
        #    (Keyboard preview), gnome-online-accounts + librest (Online
        #    Accounts), CUPS + Samba (Printers), ModemManager (WWan), udisks +
        #    krb5 (System). Samba/GOA drag in the GnuTLS stack (nettle,
        #    libunistring, gmp, libtasn1) plus popt and libtirpc.
        pkgs.libgtop,
        pkgs.libpwquality,
        pkgs.colord_gtk,
        pkgs.libwacom,
        pkgs.tecla,
        pkgs.librest,
        pkgs.goa,
        pkgs.cups,
        pkgs.samba,
        pkgs.gnutls,
        pkgs.nettle,
        pkgs.libunistring,
        pkgs.popt,
        pkgs.libtirpc,
        pkgs.modemmanager,
        pkgs.krb5,
        pkgs.udisks,
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
              # packages already installed.
              ldconfig -X

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
