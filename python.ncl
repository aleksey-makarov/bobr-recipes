let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let python_src = fun version => fun hash => {
    name = "python-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = [
        "https://www.python.org/ftp/python/%{version}/Python-%{version}.tar.xz",
      ],
    },
  }
  in

  let flit_core_src = {
    name = "flit-core-src-3.12.0",
    tag = "Source",
    object_hash = "18f63100d6f94385c6ed57a72073443e1a71a4acb4339491615d0f16d6ff01b2",
    origin = {
      tag = "Http",
      url = [
        "https://pypi.org/packages/source/f/flit-core/flit_core-3.12.0.tar.gz",
      ],
    },
  }
  in

  let packaging_src = {
    name = "packaging-src-25.0",
    tag = "Source",
    object_hash = "d443872c98d677bf60f6a1f2f8c1cb748e8fe762d2bf9d3148b5599295b0fc4f",
    origin = {
      tag = "Http",
      url = [
        "https://files.pythonhosted.org/packages/source/p/packaging/packaging-25.0.tar.gz",
      ],
    },
  }
  in

  let wheel_src = {
    name = "wheel-src-0.46.1",
    tag = "Source",
    object_hash = "fd477efb5da0f7df1d3c76c73c14394002c844451bd63229d8570f376f5e6a38",
    origin = {
      tag = "Http",
      url = [
        "https://pypi.org/packages/source/w/wheel/wheel-0.46.1.tar.gz",
      ],
    },
  }
  in

  let setuptools_src = {
    name = "setuptools-src-80.9.0",
    tag = "Source",
    object_hash = "f36b47402ecde768dbfafc46e8e4207b4360c654f1f3bb84475f0a28628fb19c",
    origin = {
      tag = "Http",
      url = [
        "https://pypi.org/packages/source/s/setuptools/setuptools-80.9.0.tar.gz",
      ],
    },
  }
  in

  let markupsafe_src = {
    name = "markupsafe-src-3.0.2",
    tag = "Source",
    object_hash = "ee55d3edf80167e48ea11a923c7386f4669df67d7994554387f84e7d8b0a2bf0",
    origin = {
      tag = "Http",
      url = [
        "https://pypi.org/packages/source/M/MarkupSafe/markupsafe-3.0.2.tar.gz",
      ],
    },
  }
  in

  let mako_src = {
    name = "mako-src-1.3.12",
    tag = "Source",
    object_hash = "9f778e93289bd410bb35daadeb4fc66d95a746f0b75777b942088b7fd7af550a",
    origin = {
      tag = "Http",
      url = [
        "https://pypi.org/packages/source/M/Mako/mako-1.3.12.tar.gz",
      ],
    },
  }
  in

  let pyyaml_src = {
    name = "pyyaml-src-6.0.3",
    tag = "Source",
    object_hash = "d76623373421df22fb4cf8817020cbb7ef15c725b9d5e45f17e189bfc384190f",
    origin = {
      tag = "Http",
      url = [
        "https://pypi.org/packages/source/P/PyYAML/pyyaml-6.0.3.tar.gz",
      ],
    },
  }
  in

  let jinja2_src = {
    name = "jinja2-src-3.1.6",
    tag = "Source",
    object_hash = "0137fb05990d35f1275a587e9aee6d56da821fc83491a0fb838183be43f66d6d",
    origin = {
      tag = "Http",
      url = [
        "https://pypi.org/packages/source/J/Jinja2/jinja2-3.1.6.tar.gz",
      ],
    },
  }
  in

  let docutils_src = {
    name = "docutils-src-0.21.2",
    tag = "Source",
    object_hash = "3a6b18732edf182daa3cd12775bbb338cf5691468f91eeeb109deff6ebfa986f",
    origin = {
      tag = "Http",
      url = [
        "https://pypi.org/packages/source/d/docutils/docutils-0.21.2.tar.gz",
      ],
    },
  }
  in

  let meson_src = {
    name = "meson-src-1.8.3",
    tag = "Source",
    object_hash = "f118aa910fc0a137cc2dd0122232dbf82153d9a12fb5b0f5bb64896f6a157abf",
    origin = {
      tag = "Http",
      url = [
        "https://github.com/mesonbuild/meson/releases/download/1.8.3/meson-1.8.3.tar.gz",
      ],
    },
  }
  in

  let ninja_src = {
    name = "ninja-src-1.13.1",
    tag = "Source",
    object_hash = "f0055ad0369bf2e372955ba55128d000cfcc21777057806015b45e4accbebf23",
    origin = {
      tag = "Http",
      url = [
        "https://github.com/ninja-build/ninja/archive/v1.13.1/ninja-1.13.1.tar.gz",
      ],
    },
  }
  in

  let python_modules_helper = {
    name = "buildscript-python-modules",
    tag = "Source",
    object_hash = import "python-modules.sh.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "python-modules.sh",
    },
  }
  in

  let python_build_rootfs = {
    name = "python-build-rootfs",
    tag = "TreeMerge",
    config = {},
    inputs =
      { base = pkgs.system_rootfs_2 }
      & recipe.numbered_inputs [
        pkgs.expat,
        pkgs.libffi,
      ],
  }
  in

  let python_gen1 = {
    version | default = "3.13.7",
    source_object_hash | default = "5462f9099dfd30e238def83c71d91897d8caa5ff6ebc7a50f14d4802cdaaa79a",
    name = "python-gen1-%{version}",
    tag = "AutotoolsRootfs",
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
          "@{out}/usr/bin/python",
        ],
      },
    },
    inputs = {
      _rootfs = pkgs.buildpack_deps_rootfs,
      source = python_src version source_object_hash,
    },
  }
  in

  let python = {
    version | default = "3.13.7",
    source_object_hash | default = "5462f9099dfd30e238def83c71d91897d8caa5ff6ebc7a50f14d4802cdaaa79a",
    name = "python-%{version}",
    tag = "AutotoolsRootfs",
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
      python_modules = [
        "flit_core",
        "packaging",
        "wheel",
        "setuptools",
        "MarkupSafe",
        "Mako",
        "PyYAML",
        "Jinja2",
        "docutils",
        "meson",
      ],
      post_install = [
        {
          name = "install_python_modules",
          run_as = "root",
          cwd = "@{build}",
          argv = [
            "/bin/bash",
            "@{modules_helper}",
          ],
          # Build PyYAML as pure Python: the build rootfs has neither Cython nor
          # libyaml, and this skips the optional C extension instead of failing.
          env = {
            PYYAML_FORCE_LIBYAML = "0",
          },
        },
        {
          name = "link_python",
          run_as = "root",
          argv = [
            "ln",
            "-svf",
            "python3",
            "@{out}/usr/bin/python",
          ],
        },
      ],
    },
    inputs = {
      _rootfs = python_build_rootfs,
      source = python_src version source_object_hash,
      modules_helper = python_modules_helper,
      flit_core = flit_core_src,
      packaging = packaging_src,
      wheel = wheel_src,
      setuptools = setuptools_src,
      MarkupSafe = markupsafe_src,
      Mako = mako_src,
      PyYAML = pyyaml_src,
      Jinja2 = jinja2_src,
      docutils = docutils_src,
      meson = meson_src,
      ninja = ninja_src,
    },
  }
  in

  {
    include [
      python_gen1,
      python,
    ],
  }
