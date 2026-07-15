# gdm -- GNOME Display Manager. Two roles here: it provides the Gdm-1.0 typelib
# (from libgdm) that gnome-shell imports at startup (the login/greeter machinery
# runs inside gnome-shell itself), and it is the login/session launcher we use
# to start the Wayland GNOME session. Meson build, Wayland-only: X11/XDMCP
# support, Plymouth, SELinux and Linux audit are all off, so the X server, GTK3
# (only pulled in by XDMCP), and plymouth are not needed. logind provider is
# systemd. PAM config is left as 'none' at build time; the actual PAM files are
# wired into the rootfs separately.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let gdm_src = fun version =>
    fun hash =>
      {
        name = "gdm-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/gdm/49/gdm-%{version}.tar.xz",
        },
      }
  in

  let gdm = {
    version | default = "49.3",
    source_object_hash
      | default
      = "539491ff0ddffe392b0f32e2b12f4179b60796c100cfe03fe6f83ee91b34496c",
    name = "gdm-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.accountsservice,
        pkgs.systemd_dev,
        pkgs.libgudev,
        pkgs.json_glib,
        pkgs.linux_pam,
        pkgs.dbus,
        pkgs.dconf,
        pkgs.gobject_introspection,
        pkgs.python,
        pkgs.gettext,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.accountsservice,
        pkgs.systemd_libs,
        pkgs.libgudev,
        pkgs.json_glib,
        pkgs.linux_pam,
        pkgs.dbus,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        # Merged-usr: /usr/sbin is a symlink to bin, so send the daemon there.
        "--sbindir=/usr/bin",
        "-Dx11-support=false",
        "-Dwayland-support=true",
        "-Dplymouth=disabled",
        "-Dselinux=disabled",
        "-Dlibaudit=disabled",
        "-Dxdmcp=disabled",
        "-Ddefault-pam-config=none",
      ],
    },
    inputs = {
      source = gdm_src version source_object_hash,
      # Removes subdir('docs') (gnome.yelp needs itstool, which we do not ship
      # and gdm offers no option to disable). Applied by the synthetic builder
      # (input name matches ^patch).
      patch_no_docs = {
        name = "gdm-no-docs-patch",
        tag = "Source",
        object_hash = import "gdm-no-docs.patch.fsobj-hash" as 'Text,
        origin = {
          tag = "RecipePath",
          path = "gdm/gdm-no-docs.patch",
        },
      },
    },
  }
  in

  {
    include [
      gdm,
    ],
  }
