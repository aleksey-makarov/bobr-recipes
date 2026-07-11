
fun pkgs =>
  let weston_src = fun version => fun hash => {
    name = "weston-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://gitlab.freedesktop.org/wayland/weston/-/releases/%{version}/downloads/weston-%{version}.tar.xz",
    },
  }
  in

  # Reference Wayland compositor, used to validate the graphical session path
  # (step 3). DRM backend + GL renderer (Mesa/virgl), desktop-shell + demo
  # clients (weston-terminal). Seat management via libseat/seatd (not
  # systemd/logind yet). No X/Xwayland, no RDP/VNC/pipewire/remoting.
  let weston = {
    version | default = "15.0.1",
    source_object_hash | default = "551d039bfb0c837ba5a4d027cdb8ee16bded0eedb789821f8025d8a64b791f6d",
    name = "weston-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.wayland,
        pkgs.wayland_protocols,
        pkgs.libxkbcommon,
        pkgs.libinput,
        pkgs.pixman,
        pkgs.seatd,
        pkgs.cairo,
        pkgs.libdrm,
        pkgs.mesa,
        pkgs.freetype,
        pkgs.fontconfig,
        pkgs.libpng,
        pkgs.libdisplay_info,
        pkgs.systemd_dev,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.wayland,
        pkgs.libxkbcommon,
        pkgs.libinput,
        pkgs.pixman,
        pkgs.seatd,
        pkgs.cairo,
        pkgs.libdrm_libs,
        pkgs.mesa,
        pkgs.freetype,
        pkgs.fontconfig,
        pkgs.libpng,
        pkgs.libdisplay_info,
        pkgs.systemd_libs,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "--wrap-mode=nodownload",
        "-Dbackend-drm=true",
        "-Dbackend-default=drm",
        "-Dbackend-headless=false",
        "-Dbackend-wayland=false",
        "-Dbackend-x11=false",
        "-Dbackend-pipewire=false",
        "-Dbackend-rdp=false",
        "-Dbackend-vnc=false",
        "-Drenderer-gl=true",
        # Vulkan renderer deferred (see TODO_vulkan_guest.md); we render via GL
        # (virgl). Without this, weston requires a vulkan SDK it can't find.
        "-Drenderer-vulkan=false",
        "-Dxwayland=false",
        "-Dshell-desktop=true",
        "-Dshell-ivi=false",
        "-Dshell-kiosk=false",
        # Lua shell defaults on and needs Lua >= 5.4 (not packaged); we use
        # desktop-shell.
        "-Dshell-lua=false",
        # Demo clients (weston-editor/image/flower/dnd/...) use the toytoolkit
        # and weston-editor hard-requires pangocairo; off to avoid the
        # pango/glib chain for now. Note weston-terminal is NOT here -- it is a
        # -Dtools entry (default on) and stays built; likewise -Dsimple-clients.
        "-Ddemo-clients=false",
        "-Dcolor-management-lcms=false",
        "-Dimage-jpeg=false",
        "-Dimage-webp=false",
        "-Dremoting=false",
        "-Dpipewire=false",
        "-Dwcap-decode=false",
        # The deprecated features (VA-API screencast, RDP screenshare, the old
        # fullscreen-shell -> superseded by kiosk-shell) all default to off, so
        # we simply don't enable them rather than touch the deprecated options.
        # libseat is the launcher in weston 15 (auto-detected via pkg-config;
        # provided by seatd). systemd/logind integration off -- we use seatd.
        "-Dsystemd=false",
        "-Ddoc=false",
      ],
    },
    inputs = {
      source = weston_src version source_object_hash,
    },
  }
  in

  {
    include [
      weston,
    ],
  }
