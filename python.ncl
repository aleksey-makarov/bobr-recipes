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
    inputs = {
      base = pkgs.system_image_2,
      inputs = [
        pkgs.expat,
        pkgs.libffi,
      ],
    },
  }
  in

  let python_gen1 =
    recipe.binary
      "python-gen1-3.13.7"
      {
        script_config = {
          build_layout = "in-tree",
          pre_configure = m%"
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
          configure_args = [
            "--without-ensurepip",
          ],
          post_install = "ln -svf python3 \"${MBUILD_INSTALL_DIR}/usr/bin/python\"",
        },
      }
      pkgs.host_image
      pkgs.buildscript_autotools
      [python_src]
  in

  let python =
    recipe.binary
      "python-3.13.7"
      {
        steps = [
          recipe.steps.step "configure" "build-user" "${source}" ["${script}", "configure"],
          recipe.steps.step "build" "build-user" "${build_dir}" ["${script}", "build"],
          recipe.steps.step "install" "root" "${build_dir}" ["${script}", "install"],
          recipe.steps.step
            "install_python_modules"
            "root"
            "${build_dir}"
            [
              "/bin/bash",
              "${source1}",
              "install-extras",
            ],
          recipe.steps.step "post_install" "root" "${build_dir}" ["${script}", "post_install"],
        ],
        script_config = {
          configure_args = [
            "--enable-shared",
            "--with-system-expat",
            "--enable-optimizations",
            "--without-static-libpython",
          ],
          python_modules = [
            {
              source_input = "sources2",
              install_name = "flit_core",
            },
            {
              source_input = "sources3",
              install_name = "packaging",
            },
            {
              source_input = "sources4",
              install_name = "wheel",
            },
            {
              source_input = "sources5",
              install_name = "setuptools",
            },
            {
              source_input = "sources6",
              install_name = "Markupsafe",
            },
            {
              source_input = "sources7",
              install_name = "Jinja2",
            },
            {
              source_input = "sources8",
              install_name = "meson",
            },
          ],
          ninja_source_input = "sources9",
          post_install = m%"
          ln -svf python3 /usr/bin/python
          ln -svf python3 "${MBUILD_INSTALL_DIR}/usr/bin/python"
        "%,
        },
      }
      python_build_image
      pkgs.buildscript_autotools
      [
        python_src,
        python_modules_helper,
        flit_core_src,
        packaging_src,
        wheel_src,
        setuptools_src,
        markupsafe_src,
        jinja2_src,
        meson_src,
        ninja_src,
      ]
  in

  {
    include [
      python_src,
      python_gen1,
      python,
    ],
  }
