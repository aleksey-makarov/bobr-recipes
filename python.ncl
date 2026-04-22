let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let python_src = {
    name = "python-src-3.13.7",
    tag = "Fetch",
    config = {
      url = [
        "https://www.python.org/ftp/python/3.13.7/Python-3.13.7.tar.xz",
      ],
      hash = "md5:256cdb3bbf45cdce7499e52ba6c36ea3",
    },
    inputs = {},
  }
  in

  let flit_core_src = {
    name = "flit-core-src-3.12.0",
    tag = "Fetch",
    config = {
      url = [
        "https://pypi.org/packages/source/f/flit-core/flit_core-3.12.0.tar.gz",
      ],
      hash = "md5:c538415c1f27bd69cbbbf3cdd5135d39",
    },
    inputs = {},
  }
  in

  let packaging_src = {
    name = "packaging-src-25.0",
    tag = "Fetch",
    config = {
      url = [
        "https://files.pythonhosted.org/packages/source/p/packaging/packaging-25.0.tar.gz",
      ],
      hash = "md5:ab0ef21ddebe09d1803575120d3f99f8",
    },
    inputs = {},
  }
  in

  let wheel_src = {
    name = "wheel-src-0.46.1",
    tag = "Fetch",
    config = {
      url = [
        "https://pypi.org/packages/source/w/wheel/wheel-0.46.1.tar.gz",
      ],
      hash = "md5:65e09ee84af36821e3b1e9564aa91bd5",
    },
    inputs = {},
  }
  in

  let setuptools_src = {
    name = "setuptools-src-80.9.0",
    tag = "Fetch",
    config = {
      url = [
        "https://pypi.org/packages/source/s/setuptools/setuptools-80.9.0.tar.gz",
      ],
      hash = "md5:82e1d67883b713f9493659b50d13b436",
    },
    inputs = {},
  }
  in

  let markupsafe_src = {
    name = "markupsafe-src-3.0.2",
    tag = "Fetch",
    config = {
      url = [
        "https://pypi.org/packages/source/M/MarkupSafe/markupsafe-3.0.2.tar.gz",
      ],
      hash = "md5:cb0071711b573b155cc8f86e1de72167",
    },
    inputs = {},
  }
  in

  let jinja2_src = {
    name = "jinja2-src-3.1.6",
    tag = "Fetch",
    config = {
      url = [
        "https://pypi.org/packages/source/J/Jinja2/jinja2-3.1.6.tar.gz",
      ],
      hash = "md5:66d4c25ff43d1deaf9637ccda523dec8",
    },
    inputs = {},
  }
  in

  let meson_src = {
    name = "meson-src-1.8.3",
    tag = "Fetch",
    config = {
      url = [
        "https://github.com/mesonbuild/meson/releases/download/1.8.3/meson-1.8.3.tar.gz",
      ],
      hash = "md5:08221d2f515e759686f666ff6409a903",
    },
    inputs = {},
  }
  in

  let ninja_src = {
    name = "ninja-src-1.13.1",
    tag = "Fetch",
    config = {
      url = [
        "https://github.com/ninja-build/ninja/archive/v1.13.1/ninja-1.13.1.tar.gz",
      ],
      hash = "md5:c35f8f55f4cf60f1a916068d8f45a0f8",
    },
    inputs = {},
  }
  in

  let python_modules_helper = {
    name = "buildscript-python-modules",
    tag = "Text",
    config = {
      source = import "python-modules.sh" as 'Text,
    },
    inputs = {},
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
    tag = "Autotools",
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
      image = pkgs.host_image,
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
