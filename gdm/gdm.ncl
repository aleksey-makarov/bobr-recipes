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
  # download.gnome.org groups gdm tarballs by major version ("50" for 50.1).
  let series = fun v => std.array.at 0 (std.string.split "." v) in

  let gdm_src = fun version =>
    fun hash =>
      {
        name = "gdm-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/gdm/%{series version}/gdm-%{version}.tar.xz",
        },
      }
  in

  let gdm = {
    version | default = "50.1",
    source_object_hash
      | default
      = "770159373512192410f412b5d0c4678ec1573f1ae4b39c81fe75861fe8890174",
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
        "-Dplymouth=disabled",
        "-Dselinux=disabled",
        "-Dlibaudit=disabled",
        "-Ddefault-pam-config=none",
      ],
      # gdm installs a stock /etc/gdm/custom.conf; drop it so the one shipped in
      # the gnome runtime tree (with WaylandEnable + automatic login) is the sole
      # provider and the rootfs merge does not conflict on it.
      post_install = {
        name = "drop_default_custom_conf",
        run_as = "root",
        argv = ["/bin/sh", "-ec", "rm -f @{out}/etc/gdm/custom.conf"],
      },
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
