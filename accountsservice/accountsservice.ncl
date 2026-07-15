# accountsservice -- D-Bus service (org.freedesktop.Accounts) for querying and
# manipulating user accounts. gnome-shell loads its AccountsService-1.0 typelib
# at startup (user menu / lock screen), and gdm links libaccountsservice, so it
# is a hard dependency of the GNOME session. Meson build; introspection is on
# (that is what produces the typelib gnome-shell needs), vala bindings and docs
# are off. Session tracking via systemd-logind (elogind off).
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let accountsservice_src = fun version =>
    fun hash =>
      {
        name = "accountsservice-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://www.freedesktop.org/software/accountsservice/accountsservice-%{version}.tar.xz",
        },
      }
  in

  let accountsservice = {
    version | default = "23.13.9",
    source_object_hash
      | default
      = "adda4cdeae24fa0992e7df3ffff9effa7090be3ac233a3edfdf69d5a9c9b924f",
    name = "accountsservice-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.polkit,
        pkgs.dbus,
        pkgs.systemd_dev,
        pkgs.libxcrypt,
        pkgs.gobject_introspection,
        pkgs.python,
        pkgs.gettext,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.polkit,
        pkgs.dbus,
        pkgs.systemd_libs,
        pkgs.libxcrypt,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dvapi=false",
      ],
    },
    inputs = {
      source = accountsservice_src version source_object_hash,
      # Build fixes: substitute the version literally (our source extraction
      # strips the accountsservice-<version> directory generate-version.sh reads)
      # and drop subdir('tests') (the bundled mocklibc does not compile with a
      # modern gcc). Applied by the synthetic builder (input name matches ^patch).
      patch_build_fixes = {
        name = "accountsservice-build-fixes-patch",
        tag = "Source",
        object_hash = import "accountsservice-build-fixes.patch.fsobj-hash" as 'Text,
        origin = {
          tag = "RecipePath",
          path = "accountsservice/accountsservice-build-fixes.patch",
        },
      },
    },
  }
  in

  {
    include [
      accountsservice,
    ],
  }
