# NetworkManager -- the network configuration daemon and its client library
# libnm. gnome-settings-daemon requires NetworkManager unconditionally on Linux,
# and gnome-shell's network indicator uses the NM-1.0 typelib; both come from
# here. Meson build tuned for a QEMU/virtio guest, roughly as a distro's
# server/cloud image builds it: the core daemon, libnm, nmcli and introspection
# are on; the keyfile connection store (the modern default) is used. Hardware and
# features that make no sense in the VM or would pull extra stacks are off --
# Wi-Fi/wext/iwd, PPP, ModemManager/ofono (mobile broadband), Open vSwitch, team,
# Bluetooth DUN, nmtui (newt), cloud-setup and connectivity check (libcurl),
# SELinux, audit, eBPF, NBFT, docs/man/tests. Crypto uses NSS; session tracking
# and suspend/resume go through systemd-logind.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let networkmanager_src = fun version =>
    fun hash =>
      {
        name = "networkmanager-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://gitlab.freedesktop.org/api/v4/projects/411/packages/generic/NetworkManager/%{version}/NetworkManager-%{version}.tar.xz",
        },
      }
  in

  let networkmanager = {
    version | default = "1.56.1",
    source_object_hash
      | default
      = "b0ee9a89dfba39d2a1a69d60868be99096d3b6b66a1a22bf8a9d5a38b8aed50e",
    name = "networkmanager-%{version}",
    tag = "MesonInstall",
    deps = {
      build = [
        pkgs.glib,
        pkgs.util_linux,
        pkgs.systemd_dev,
        pkgs.dbus,
        pkgs.libndp,
        pkgs.nss,
        pkgs.nspr,
        pkgs.libpsl,
        pkgs.readline,
        pkgs.ncurses,
        pkgs.polkit,
        pkgs.gobject_introspection,
        pkgs.python,
        pkgs.perl,
        pkgs.gettext,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.util_linux_libs,
        pkgs.systemd_libs,
        pkgs.dbus,
        pkgs.libndp,
        pkgs.nss,
        pkgs.nspr,
        pkgs.libpsl,
        pkgs.readline,
        pkgs.ncurses,
        pkgs.polkit,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        # Merged-usr: /usr/sbin is a symlink to bin, so send the daemon there.
        "--sbindir=/usr/bin",
        "-Dcrypto=nss",
        "-Dintrospection=true",
        "-Dvapi=false",
        "-Dnmcli=true",
        "-Dnmtui=false",
        "-Dwifi=false",
        "-Dwext=false",
        "-Diwd=false",
        "-Dppp=false",
        "-Dmodem_manager=false",
        "-Dofono=false",
        "-Dovs=false",
        "-Dteamdctl=false",
        "-Dbluez5_dun=false",
        "-Dnm_cloud_setup=false",
        "-Dconcheck=false",
        "-Dnbft=false",
        "-Debpf=false",
        "-Dselinux=false",
        "-Dlibaudit=no",
        "-Dpolkit=true",
        "-Dsession_tracking=systemd",
        "-Dsuspend_resume=systemd",
        "-Dlibpsl=true",
        "-Dreadline=libreadline",
        "-Ddocs=false",
        "-Dman=false",
        "-Dtests=no",
      ],
      # NetworkManager-initrd.service is a dracut-in-initramfs unit; it declares
      # the same D-Bus name (org.freedesktop.NetworkManager) as the normal
      # service, so systemd loads it, sees the bus name claimed twice and logs a
      # boot-time error. We have no NM-in-initramfs, so drop the unit.
      post_install = {
        name = "drop_initrd_unit",
        run_as = "root",
        argv = ["/bin/sh", "-ec", "rm -f /usr/lib/systemd/system/NetworkManager-initrd.service"],
      },
    },
    inputs = {
      source = networkmanager_src version source_object_hash,
    },
  }
  in

  {
    include [
      networkmanager,
    ],
  }
