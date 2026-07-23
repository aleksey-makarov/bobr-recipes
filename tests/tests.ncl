# Test targets.
#
# `test_all_recipes` -- the buildable artifacts group for a normal build; it
# carries no checks.
#
# `test_all_rootfs` -- runtime-closure checks over every rootfs used in the
# `test_all_recipes` graph. It discovers every node used as a `_rootfs` input of
# a Sandbox/SandboxInstall (i.e. every build environment), plus the shipped
# images (packed via `_tree`, not `_rootfs`, so the walk misses them), runs a
# check over each, bundles the reports, and a gate step fails the build if any
# rootfs reported errors.
#
# Every check runs from OUTSIDE the checked tree: the checker sandbox uses a
# tool-rich OCI rootfs (`buildpack_deps_rootfs`) as its `_rootfs`, with the tree
# to check mounted as the `_target` fs-tree input -- so even minimal rootfs (the
# initramfs) are checkable. The common script is rootfs-check.sh; the shipped
# images additionally source rootfs-check-image.sh (image-specific checks).
#
# `test_all_rootfs` is deliberately NOT part of `test_all_recipes`, so the normal
# build stays lean; run it on demand / in CI via `bobr build test_all_rootfs`.
# Every rootfs it needs is already built by `test_all_recipes`, so only the
# (cheap) check sandboxes are new work.
let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let test_all_recipes = {
    name = "test-all-recipes",
    tag = "Group",
    config = {},
    inputs =
      recipe.numbered_inputs [
        pkgs.linux,
        pkgs.erofs_rootfs,
        pkgs.initrd,
        pkgs.gnome_erofs_rootfs,
      ],
  }
  in

  let rootfs_check_source = {
    name = "rootfs-check-source",
    tag = "Source",
    object_hash = import "rootfs-check.sh.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "tests/rootfs-check.sh",
    },
  }
  in

  let rootfs_check_image_source = {
    name = "rootfs-check-image-source",
    tag = "Source",
    object_hash = import "rootfs-check-image.sh.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "tests/rootfs-check-image.sh",
    },
  }
  in

  let rootfs_check_gate_source = {
    name = "rootfs-check-gate-source",
    tag = "Source",
    object_hash = import "rootfs-check-gate.sh.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "tests/rootfs-check-gate.sh",
    },
  }
  in

  # Per-rootfs approved failures: substring patterns of failure lines that the
  # check reports as INFO instead of failing on. These are irreducible blind
  # spots of a static per-ELF scan -- private-prefix libraries resolved only via
  # the loading binary's RUNPATH or a build-time LD_LIBRARY_PATH, which the scan
  # cannot see. Each entry is (specific rootfs -> specific problem); ANY other
  # failure on the same rootfs still fails. Keyed by the rootfs node name (so a
  # version bump forces a re-review, which is intended).
  let suppress_by_rootfs = {
    # buildpack-deps (external Debian OCI image) ships Subversion's optional
    # kwallet/gnome-keyring auth plugins, which dlopen KDE/Qt/libsecret only for
    # interactive auth -- never in a build. Those libs aren't in the image, so
    # the plugins have dangling NEEDED, but they are never loaded. Not our
    # recipe. glibc-bootstrap is the same buildpack image plus gawk/bison.
    "buildpack-deps-rootfs" = ["libsvn_auth_kwallet", "libsvn_auth_gnome_keyring"],
    "glibc-bootstrap-rootfs" = ["libsvn_auth_kwallet", "libsvn_auth_gnome_keyring"],
    # glib's gen1 bootstrap binaries live in the private /usr/lib/glib-gen1
    # prefix and find their libs via LD_LIBRARY_PATH set during glib's build.
    "glib-2.88.2-build-rootfs" = ["/usr/lib/glib-gen1/"],
    "gobject-introspection-1.86.0-build-rootfs" = ["/usr/lib/glib-gen1/"],
    # libsystemd-core loads libsystemd-shared (same /usr/lib/systemd dir) via the
    # systemd binaries' RUNPATH, not its own.
    "initrd-rootfs" = ["/usr/lib/systemd/libsystemd-core"],
    # Prebuilt clang toolchain: libc++/libunwind live in its triple dir and
    # resolve via clang's build-time LD_LIBRARY_PATH; the ompd GDB helper is dead
    # (references an old python, only ever loaded inside gdb).
    "mozjs-140.12.0esr-build-rootfs" = [
      "/usr/lib/x86_64-unknown-linux-gnu/",
      "/usr/share/gdb/python/ompd/",
    ],
  }
  in

  # Closure check of one rootfs: run rootfs-check.sh in the tool OCI rootfs
  # (`_rootfs`), with the tree to check mounted as `_target`. Captured as a
  # plain-object directory holding one report file.
  let mk_rootfs_check = fun check_name =>
    fun rootfs => {
      name = "rootfs-check-%{check_name}",
      tag = "Sandbox",
      config = {
        script_config = {
          name = check_name,
          suppress =
            if std.record.has_field check_name suppress_by_rootfs then
              std.record.get check_name suppress_by_rootfs
            else
              [],
        },
        steps = [
          {
            name = "check_rootfs",
            run_as = "root",
            cwd = "@{out}",
            argv = ["@{script}"],
          },
        ],
      },
      inputs = {
        _rootfs = pkgs.buildpack_deps_rootfs,
        _target = rootfs,
        script = rootfs_check_source,
      },
    }
  in

  # Image check: the same OUTSIDE model, but additionally sources
  # rootfs-check-image.sh (via `special_image`) for the image-specific checks
  # (os-release layout, shebang interpreters, GNOME typelibs, graphics stack),
  # gated by `extra_config` flags. Used only for the shipped images below.
  let mk_image_check = fun check_name =>
    fun image =>
      fun extra_config => {
        name = "rootfs-check-image-%{check_name}",
        tag = "Sandbox",
        config = {
          script_config = { name = check_name } & extra_config,
          steps = [
            {
              name = "check_image",
              run_as = "root",
              cwd = "@{out}",
              argv = ["@{script}"],
            },
          ],
        },
        inputs = {
          _rootfs = pkgs.buildpack_deps_rootfs,
          _target = image,
          script = rootfs_check_source,
          special_image = rootfs_check_image_source,
        },
      }
  in

  let test_rootfs = mk_image_check "rootfs" pkgs.rootfs {} in

  let test_gnome_rootfs =
    mk_image_check "gnome-rootfs" pkgs.gnome_rootfs {
      check_graphics = "true",
      check_gnome = "true",
      # gnome-shell's JS references these GI namespaces, but they are only loaded
      # behind compile-time flags we built without (NetworkManager, bluetooth) or
      # a runtime try/catch (Malcontent parental controls), so a missing typelib
      # is harmless -- reported as INFO, not a failure. The unconditionally
      # required imports (Geoclue, GWeather, Rsvg) are NOT listed here: their
      # typelibs must be present or the shell crashes at startup
      # (misc/dependencies.js). Everything else must have a typelib.
      gnome_optional_typelibs = "GnomeBluetooth Malcontent",
    }
  in

  # Closure checks over exactly the `_rootfs` inputs of every Sandbox/
  # SandboxInstall in the test_all_recipes graph -- i.e. every build environment.
  # This is precisely what the walk returns; nothing is added to or removed from
  # it here.
  let build_rootfs_checks =
    let targets = recipe.collect_rootfs_inputs pkgs test_all_recipes in
    std.array.map
      (fun rname => mk_rootfs_check rname (std.record.get rname targets))
      (std.record.fields targets)
  in

  # The shipped images are packed via `_tree`, not `_rootfs`, so the walk never
  # reaches them -- check them explicitly. initrd_rootfs gets a closure check;
  # rootfs/gnome_rootfs use the richer image checks (which add the image-specific
  # checks). All produce the same one-file `status:` report, so the gate is
  # uniform.
  let image_checks = [
    mk_rootfs_check pkgs.initrd_rootfs.name pkgs.initrd_rootfs,
    test_rootfs,
    test_gnome_rootfs,
  ]
  in

  let checks = build_rootfs_checks @ image_checks in

  # Fan-in via `Bundle`: collapse the per-rootfs report directories into ONE
  # object, so the gate bind-mounts a single input regardless of how many rootfs
  # were checked. `numbered_inputs` gives valid (`nNNN`) bundle slot keys; the
  # rootfs identity is inside each report (`name:` line).
  let reports_bundle = {
    name = "rootfs-check-reports",
    tag = "Bundle",
    config = {},
    inputs = recipe.numbered_inputs checks,
  }
  in

  let test_all_rootfs = {
    name = "test-all-rootfs",
    tag = "Sandbox",
    config = {
      steps = [
        {
          name = "gate",
          run_as = "root",
          cwd = "@{out}",
          argv = ["@{script}"],
        },
      ],
    },
    inputs = {
      _rootfs = pkgs.buildpack_deps_rootfs,
      script = rootfs_check_gate_source,
      reports = reports_bundle,
    },
  }
  in

  # Build the artifacts and run the rootfs checks in one go.
  let test_all = {
    name = "test-all",
    tag = "Group",
    config = {},
    inputs =
      recipe.numbered_inputs [
        test_all_recipes,
        test_all_rootfs,
      ],
  }
  in

  {
    include [
      test_all_recipes,
      test_all_rootfs,
      test_all,
    ],
  }
