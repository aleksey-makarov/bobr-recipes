let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let python_src = {
    name = "python-src-3.13.7",
    tag = "Source",
    object_hash = "acd88f182c16775a0b20160c5412dc5602c00a26bccb9d510aae13c00db4b772",
    origin = {
      type = "http",
      url = [
        "https://www.python.org/ftp/python/3.13.7/Python-3.13.7.tar.xz",
      ],
      unpack = true,
    },
    meta = {},
  }
  in

  let flit_core_src = {
    name = "flit-core-src-3.12.0",
    tag = "Source",
    object_hash = "4ae18f5a18bd14a7f0c81f0898c9173e7bf6e3da6f7797b38dd7598e9c0df83e",
    origin = {
      type = "http",
      url = [
        "https://pypi.org/packages/source/f/flit-core/flit_core-3.12.0.tar.gz",
      ],
      unpack = true,
    },
    meta = {},
  }
  in

  let packaging_src = {
    name = "packaging-src-25.0",
    tag = "Source",
    object_hash = "eef46092fcf8c09e867314008a279f878dc2082b4836b2cef40c0e6f1bffb038",
    origin = {
      type = "http",
      url = [
        "https://files.pythonhosted.org/packages/source/p/packaging/packaging-25.0.tar.gz",
      ],
      unpack = true,
    },
    meta = {},
  }
  in

  let wheel_src = {
    name = "wheel-src-0.46.1",
    tag = "Source",
    object_hash = "87ee5389942362742e150c7fde90082fa12f60920e7d57f993b17e00714f1c9c",
    origin = {
      type = "http",
      url = [
        "https://pypi.org/packages/source/w/wheel/wheel-0.46.1.tar.gz",
      ],
      unpack = true,
    },
    meta = {},
  }
  in

  let setuptools_src = {
    name = "setuptools-src-80.9.0",
    tag = "Source",
    object_hash = "3ce8dc0ff6d650b87bf097d0060d6072d3ee07501b94cb2da34446bf6d9d33ec",
    origin = {
      type = "http",
      url = [
        "https://pypi.org/packages/source/s/setuptools/setuptools-80.9.0.tar.gz",
      ],
      unpack = true,
    },
    meta = {},
  }
  in

  let markupsafe_src = {
    name = "markupsafe-src-3.0.2",
    tag = "Source",
    object_hash = "09b2777975dde2530652f132ccad00ec10e0b1d66ce9c9b9d74565e92cc81b87",
    origin = {
      type = "http",
      url = [
        "https://pypi.org/packages/source/M/MarkupSafe/markupsafe-3.0.2.tar.gz",
      ],
      unpack = true,
    },
    meta = {},
  }
  in

  let jinja2_src = {
    name = "jinja2-src-3.1.6",
    tag = "Source",
    object_hash = "8ec4e4952cb7d50ddc246f33c0c42f637e28af501c953a2f95b9d056badfb314",
    origin = {
      type = "http",
      url = [
        "https://pypi.org/packages/source/J/Jinja2/jinja2-3.1.6.tar.gz",
      ],
      unpack = true,
    },
    meta = {},
  }
  in

  let meson_src = {
    name = "meson-src-1.8.3",
    tag = "Source",
    object_hash = "eb8f23b24a47a7c581270ed0f2367d7b97c5e6b3133416b3c7d90b1d3fbfd4a6",
    origin = {
      type = "http",
      url = [
        "https://github.com/mesonbuild/meson/releases/download/1.8.3/meson-1.8.3.tar.gz",
      ],
      unpack = true,
    },
    meta = {},
  }
  in

  let ninja_src = {
    name = "ninja-src-1.13.1",
    tag = "Source",
    object_hash = "97375f11d9a92187509c71fb91b88f763ed535f12a5011d565058c512eb9ebab",
    origin = {
      type = "http",
      url = [
        "https://github.com/ninja-build/ninja/archive/v1.13.1/ninja-1.13.1.tar.gz",
      ],
      unpack = true,
    },
    meta = {},
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
    meta = {},
  }
  in

  let python_build_image = {
    name = "python-build-image",
    tag = "Image",
    config = { ref_name | default = "python-build-image" } & {},
    inputs =
      { base = pkgs.system_image_2 }
      & recipe.numbered_inputs [
        pkgs.expat,
        pkgs.libffi,
      ],
  }
  in

  let python_gen1 = {
    name = "python-gen1-3.13.7",
    tag = "AutotoolsSandbox",
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
            # host libraries and leak them into system-image-0.
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
    tag = "Autotools",
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
      image = python_build_image,
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
