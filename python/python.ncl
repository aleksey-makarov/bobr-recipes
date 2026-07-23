let br = import "../build-rootfs.ncl" in
# The interpreter and its build-only PyPI modules are aggregated here so pkgs.ncl
# imports only python/python.ncl (not each module file individually). Each module
# is its own PythonModule recipe (additive install of a pip-built wheel); the
# interpreter no longer bundles them.
let mk_python_flit_core = import "python-flit-core.ncl" in
let mk_python_setuptools = import "python-setuptools.ncl" in
let mk_python_packaging = import "python-packaging.ncl" in
let mk_python_wheel = import "python-wheel.ncl" in
let mk_python_six = import "python-six.ncl" in
let mk_python_markupsafe = import "python-markupsafe.ncl" in
let mk_python_jinja2 = import "python-jinja2.ncl" in
let mk_python_mako = import "python-mako.ncl" in
let mk_python_pyyaml = import "python-pyyaml.ncl" in

fun pkgs =>
  let python_src = fun version => fun hash => {
    name = "python-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://www.python.org/ftp/python/%{version}/Python-%{version}.tar.xz",
    },
  }
  in

  # Deps-derived build rootfs, replacing the curated system_rootfs_2: the native
  # toolchain plus the libraries the stdlib C extensions link. python is a default
  # Meson build dep but its own rootfs never pulls python (the deps are C
  # libraries), so no cycle.
  let python_build_rootfs =
    br.build_rootfs_closure
      pkgs
      "python-build-rootfs"
      (
        br.native_build_deps pkgs
        @ [
          pkgs.expat,
          pkgs.libffi,
          # _curses stdlib extension (mozjs's configure imports curses via
          # mach.logging -> blessed).
          pkgs.ncurses,
          # _ssl / _hashlib (mozjs's configure imports ssl via mozboot).
          pkgs.openssl,
          # _bz2, readline, _gdbm/_dbm, _uuid (util-linux libuuid). _lzma/_sqlite3
          # already build; only _tkinter (GUI, no tk) is left out.
          pkgs.bzip2,
          pkgs.readline,
          pkgs.gdbm,
          pkgs.util_linux,
          # zlib for _zlib (the snapshot carried it; native_build_deps does not).
          pkgs.zlib,
        ]
      )
  in

  let python_gen1 = {
    version | default = "3.13.7",
    source_object_hash | default = "5462f9099dfd30e238def83c71d91897d8caa5ff6ebc7a50f14d4802cdaaa79a",
    name = "python-gen1-%{version}",
    tag = "AutotoolsStageRootfs",
    config = {
      in-tree = true,
      pre_configure = {
        name = "write_setup_local",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            cat > Modules/Setup.local <<'EOF_INNER'
            # Minimal bootstrap Python: keep a self-contained interpreter and
            # disable optional extension modules that would otherwise auto-detect
            # host libraries and leak them into system-rootfs-0.
            *disabled*
            _uuid
            _ssl
            _hashlib
            _lzma
            binascii
            zlib
            _gdbm
            _ctypes
            _sqlite3
            _bz2
            _curses_panel
            _dbm
            readline
            _curses
            EOF_INNER
          "%,
        ],
      },
      configure_args = [
        "--without-ensurepip",
      ],
      post_install = {
        name = "link_python",
        run_as = "root",
        argv = [
          "ln",
          "-svf",
          "python3",
          "/stage/usr/bin/python",
        ],
      },
    },
    inputs = {
      _rootfs = pkgs.oci_buildpack_deps_rootfs,
      source = python_src version source_object_hash,
    },
  }
  in

  let python = {
    version | default = "3.13.7",
    source_object_hash | default = "5462f9099dfd30e238def83c71d91897d8caa5ff6ebc7a50f14d4802cdaaa79a",
    name = "python-%{version}",
    tag = "AutotoolsStageRootfs",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
        pkgs.zlib,
        # Built --with-system-expat, so pyexpat (xml.parsers.expat, used by
        # gdbus-codegen and others) links libexpat.so.1. _ctypes links libffi.
        # Without these in python's runtime closure, any build rootfs that pulls
        # python (Meson/Autotools default build deps) lacks them and pyexpat/
        # ctypes fail at import.
        pkgs.expat,
        pkgs.libffi,
        # _curses links libncursesw.so.6.
        pkgs.ncurses,
        # _ssl / _hashlib link libssl.so / libcrypto.so.
        pkgs.openssl_libs,
        # _bz2 -> libbz2, readline -> libreadline, _gdbm/_dbm -> libgdbm,
        # _uuid -> libuuid.so.1 (util-linux libs split).
        pkgs.bzip2,
        pkgs.readline,
        pkgs.gdbm,
        pkgs.util_linux_libs,
      ],
    },
    config = {
      configure_args = [
        "--enable-shared",
        "--with-system-expat",
        # PGO (--enable-optimizations) is not reproducible: its profile is
        # gathered from a non-deterministic training run. Use LTO instead
        # (reproducible) plus -fno-semantic-interposition to recover most of
        # the speed lost to the shared build. See nixpkgs cpython.
        "--with-lto",
        "--without-static-libpython",
      ],
      env = {
        CFLAGS_NODIST = "-fno-semantic-interposition",
      },
      post_install = {
        name = "link_python",
        run_as = "root",
        argv = [
          "ln",
          "-svf",
          "python3",
          "/stage/usr/bin/python",
        ],
      },
    },
    inputs = {
      _rootfs = python_build_rootfs,
      source = python_src version source_object_hash,
    },
  }
  in

  # `include` names each field after the identifier, so bind the applied module
  # nodes to their attribute names first (it cannot take application expressions).
  let python_flit_core = mk_python_flit_core pkgs in
  let python_setuptools = mk_python_setuptools pkgs in
  let python_packaging = mk_python_packaging pkgs in
  let python_wheel = mk_python_wheel pkgs in
  let python_six = mk_python_six pkgs in
  let python_markupsafe = mk_python_markupsafe pkgs in
  let python_jinja2 = mk_python_jinja2 pkgs in
  let python_mako = mk_python_mako pkgs in
  let python_pyyaml = mk_python_pyyaml pkgs in
  {
    include [
      python_gen1,
      python,
      python_flit_core,
      python_setuptools,
      python_packaging,
      python_wheel,
      python_six,
      python_markupsafe,
      python_jinja2,
      python_mako,
      python_pyyaml,
    ]
  }
