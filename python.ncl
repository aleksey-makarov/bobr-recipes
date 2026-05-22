let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let python_src = {
    name = "python-src-3.13.7",
    tag = "Source",
    object_hash = "355d392fe32a63391337edb790a8dbe7846aa18015b29c762f604f10c53b3259",
    origin = {
      type = "http",
      url = [
        "https://www.python.org/ftp/python/3.13.7/Python-3.13.7.tar.xz",
      ],
    },
  }
  in

  let flit_core_src = {
    name = "flit-core-src-3.12.0",
    tag = "Source",
    object_hash = "81f7fa24c4e0867051f7368d346d64923f4d4e40a764df814bc4119544dec796",
    origin = {
      type = "http",
      url = [
        "https://pypi.org/packages/source/f/flit-core/flit_core-3.12.0.tar.gz",
      ],
    },
  }
  in

  let packaging_src = {
    name = "packaging-src-25.0",
    tag = "Source",
    object_hash = "bb1361b53a95401b89259fc68190354931d5d05f20d6a654ccce63b88e413ac1",
    origin = {
      type = "http",
      url = [
        "https://files.pythonhosted.org/packages/source/p/packaging/packaging-25.0.tar.gz",
      ],
    },
  }
  in

  let wheel_src = {
    name = "wheel-src-0.46.1",
    tag = "Source",
    object_hash = "81d9a8177f1766622f39a4592f3e327634e946ff5d47afee69803affc2d35bc9",
    origin = {
      type = "http",
      url = [
        "https://pypi.org/packages/source/w/wheel/wheel-0.46.1.tar.gz",
      ],
    },
  }
  in

  let setuptools_src = {
    name = "setuptools-src-80.9.0",
    tag = "Source",
    object_hash = "e6970a31f4e65ec5ddad7b174e1ea99c94ba6524e5988ed9b2775ca3a306cedf",
    origin = {
      type = "http",
      url = [
        "https://pypi.org/packages/source/s/setuptools/setuptools-80.9.0.tar.gz",
      ],
    },
  }
  in

  let markupsafe_src = {
    name = "markupsafe-src-3.0.2",
    tag = "Source",
    object_hash = "f8bd354b669b6b5219ba54d5f3bf13bfd7d69fc28d4267633071440ea04acde7",
    origin = {
      type = "http",
      url = [
        "https://pypi.org/packages/source/M/MarkupSafe/markupsafe-3.0.2.tar.gz",
      ],
    },
  }
  in

  let jinja2_src = {
    name = "jinja2-src-3.1.6",
    tag = "Source",
    object_hash = "12be9ddb5b10bdfde02e1615dfc50ba5bc8d30f4b3f43c82e939eedebd9a1098",
    origin = {
      type = "http",
      url = [
        "https://pypi.org/packages/source/J/Jinja2/jinja2-3.1.6.tar.gz",
      ],
    },
  }
  in

  let meson_src = {
    name = "meson-src-1.8.3",
    tag = "Source",
    object_hash = "1aaa4dd29a76021f2ed874fa3c817220e60be145dbbcadcffd615eb289a1e21b",
    origin = {
      type = "http",
      url = [
        "https://github.com/mesonbuild/meson/releases/download/1.8.3/meson-1.8.3.tar.gz",
      ],
    },
  }
  in

  let ninja_src = {
    name = "ninja-src-1.13.1",
    tag = "Source",
    object_hash = "e77096af39caa7abae81a81f0749515adf889d96c1a878cc1f5bcdeb514c4bec",
    origin = {
      type = "http",
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
      type = "path",
      path = "python-modules.sh",
      mode = "direct",
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
    name = "python-gen1-3.13.7",
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
      rootfs = pkgs.buildpack_deps_rootfs,
      source = python_src,
    },
  }
  in

  let python = {
    name = "python-3.13.7",
    tag = "AutotoolsRootfs",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
        pkgs.zlib,
      ],
    },
    config = {
      configure_args = [
        "--enable-shared",
        "--with-system-expat",
        "--enable-optimizations",
        "--without-static-libpython",
      ],
      python_modules = [
        "flit_core",
        "packaging",
        "wheel",
        "setuptools",
        "MarkupSafe",
        "Jinja2",
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
      rootfs = python_build_rootfs,
      source = python_src,
      modules_helper = python_modules_helper,
      flit_core = flit_core_src,
      packaging = packaging_src,
      wheel = wheel_src,
      setuptools = setuptools_src,
      MarkupSafe = markupsafe_src,
      Jinja2 = jinja2_src,
      meson = meson_src,
      ninja = ninja_src,
    },
  }
  in

  {
    include [
      python_src,
      python_gen1,
      python,
    ],
  }
