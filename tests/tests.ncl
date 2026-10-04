# Aggregate test targets. Artifact-only targets live in `world.ncl`.
#
# `test_host_bundles` -- smoke checks over the test Mesa and QEMU HostBundles.
#
# `test_runtime_closures` -- one isolated closure check for every runtime-bearing
# fs-tree recipe (every reachable node with `deps`). Each closure contains only
# the package, its transitive `deps.runtime`, and `base_filesystem`, so unrelated
# packages cannot mask a missing runtime dependency. The raw reports also audit
# direct runtime dependency evidence; a durable aggregate audit is published
# before the final gate interprets its status.
#
# `test_bootstrap_rootfs` -- checks the small set of canonical external and
# bootstrap toolchain environments whose gen1 members do not yet have package
# runtime contracts of their own.
#
# `test_image_rootfs` -- checks the initrd and the three shipped OS rootfs trees.
# The OS checks add image-specific assertions for graphics and GNOME content.
#
# Every check runs from OUTSIDE the checked tree: the checker sandbox uses a
# tool-rich OCI rootfs (`oci_buildpack_deps_rootfs`) as its `_rootfs`, with the tree
# to check mounted as the `_target` fs-tree input -- so even minimal rootfs (the
# initramfs) are checkable. The common script is rootfs-check.sh; the shipped
# images additionally source rootfs-check-image.sh (image-specific checks).
#
# `test_all` -- all explicit checks: HostBundle smoke tests, rootfs closure
# checks, and the final toolchain smoke test. Tests are deliberately outside
# `world`; run them on demand / in CI with `bin/bobr-build.sh --target test_all`.
let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let test_host_bundles = {
    name = "test-host-bundles",
    tag = "Group",
    config = {},
    inputs =
      recipe.numbered_inputs [
        pkgs.test_host_bundle_test_mesa,
        pkgs.test_host_bundle_qemu,
        pkgs.test_host_bundle_qemu_weston,
        pkgs.test_host_bundle_qemu_gnome,
      ],
  }
  in

  # The final compiler packages are built by the gen1 compiler, so their own
  # builds do not prove that they form a usable native toolchain together.
  # Exercise the assembled final glibc/binutils/GCC rootfs directly: compile
  # and run one small program, while asserting the merged-/usr library layout
  # and the stable x86_64 ELF interpreter ABI.
  let test_final_toolchain = {
    name = "test-final-toolchain",
    tag = "Sandbox",
    config = {
      steps = [
        {
          name = "compile_and_run",
          run_as = "root",
          cwd = "@{out}",
          argv = [
            "/bin/sh",
            "-ec",
            m%"
              cat > probe.c <<'EOF'
              int main(void) { return 0; }
              EOF

              gcc -Wall -Werror -o probe probe.c
              test -d /usr/lib
              test -L /usr/lib64
              test "$(readlink /usr/lib64)" = "lib"
              test -L /lib
              test "$(readlink /lib)" = "usr/lib"
              test -L /lib64
              test "$(readlink /lib64)" = "usr/lib64"
              test "$(gcc -print-multi-os-directory)" = "../lib"
              test "$(gcc -print-multi-directory)" = "."
              program_headers="$(readelf -l probe)"
              case "$program_headers" in
                *'Requesting program interpreter: /lib64/ld-linux-x86-64.so.2'*) ;;
                *) exit 1 ;;
              esac
              loader_trace="$(LD_TRACE_LOADED_OBJECTS=1 ./probe)"
              case "$loader_trace" in
                *'libc.so.6 => /usr/lib/libc.so.6'*) ;;
                *) exit 1 ;;
              esac
              ./probe

              rm -f probe probe.c
              printf 'final toolchain smoke: ok\n' > status
            "%,
          ],
        },
      ],
    },
    inputs = {
      _rootfs = recipe.bootstrap_toolchain_rootfs pkgs "test-final-toolchain-rootfs" [],
    },
  }
  in

  let check_source = {
    name = "check-source",
    tag = "Source",
    object_hash = import "rootfs-check.sh.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "tests/rootfs-check.sh",
    },
  }
  in

  let check_image_source = {
    name = "check-image-source",
    tag = "Source",
    object_hash = import "rootfs-check-image.sh.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "tests/rootfs-check-image.sh",
    },
  }
  in

  let check_gate_source = {
    name = "check-gate-source",
    tag = "Source",
    object_hash = import "rootfs-check-gate.sh.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "tests/rootfs-check-gate.sh",
    },
  }
  in

  let runtime_closure_audit_source = {
    name = "runtime-closure-audit-source",
    tag = "Source",
    object_hash = import "runtime-closure-audit.sh.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "tests/runtime-closure-audit.sh",
    },
  }
  in

  let runtime_closure_gate_source = {
    name = "runtime-closure-gate-source",
    tag = "Source",
    object_hash = import "runtime-closure-gate.sh.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "tests/runtime-closure-gate.sh",
    },
  }
  in

  let runtime_deps_allowlist_source = {
    name = "runtime-deps-allowlist-source",
    tag = "Source",
    object_hash = import "runtime-deps-allowlist.tsv.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "tests/runtime-deps-allowlist.tsv",
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
    "oci-buildpack-deps-rootfs" = ["libsvn_auth_kwallet", "libsvn_auth_gnome_keyring"],
    "glibc-bootstrap-rootfs" = ["libsvn_auth_kwallet", "libsvn_auth_gnome_keyring"],
  }
  in

  # Closure check of one rootfs: run rootfs-check.sh in the tool OCI rootfs
  # (`_rootfs`), with the tree to check mounted as `_target`. Captured as a
  # plain-object directory holding one report file.
  let mk_rootfs_check = fun check_name =>
    fun rootfs =>
      {
        name = "check-%{check_name}",
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
          _rootfs = pkgs.oci_buildpack_deps_rootfs,
          _target = rootfs,
          script = check_source,
        },
      }
  in

  # Image check: the same OUTSIDE model, but additionally sources
  # rootfs-check-image.sh (via `special_image`) for the image-specific checks
  # (os-release layout, shebang interpreters, GNOME typelibs, graphics stack),
  # gated by `extra_config` flags. Used only for the shipped images below.
  let mk_image_check = fun check_name =>
    fun image =>
      fun extra_config =>
        {
          name = "check-image-%{check_name}",
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
            _rootfs = pkgs.oci_buildpack_deps_rootfs,
            _target = image,
            script = check_source,
            special_image = check_image_source,
          },
        }
  in

  # Collapse an arbitrary set of one-report check nodes into one Bundle, then
  # run the common gate over it. Keeping the fan-in behind one input avoids a
  # hundreds-of-mounts gate sandbox for the per-package runtime checks.
  let mk_check_gate = fun target_name =>
    fun bundle_name =>
      fun checks =>
        let reports_bundle = {
          name = bundle_name,
          tag = "Bundle",
          config = {},
          inputs = recipe.numbered_inputs checks,
        }
        in
        {
          name = target_name,
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
            _rootfs = pkgs.oci_buildpack_deps_rootfs,
            script = check_gate_source,
            reports = reports_bundle,
          },
        }
  in

  # Check every package-level runtime contract independently. The collector
  # keeps the original raw node (and therefore its deps) even when a synthetic
  # builder lowers to technical SandboxInstall/TreeMove nodes.
  let runtime_roots = recipe.collect_runtime_roots pkgs pkgs.world in
  let runtime_closure_checks =
    std.array.map
      (fun recipe_name =>
        let package = std.record.get recipe_name runtime_roots in
        let numbered_runtime_inputs = recipe.numbered_inputs package.deps.runtime in
        let direct_runtime_inputs =
          std.record.from_array (
            std.array.map
              (fun slot =>
                {
                  field = "_runtime_dep_%{slot}",
                  value = std.record.get slot numbered_runtime_inputs,
                }
              )
              (std.record.fields numbered_runtime_inputs)
          )
        in
        let direct_runtime_names =
          std.record.map (fun _ dependency => dependency.name) direct_runtime_inputs
        in
        let redundant_runtime_dependency_names =
          std.record.map
            (fun _ dependency =>
              let via =
                std.array.map
                  (fun other => other.name)
                  (
                    std.array.filter
                      (fun other =>
                        other.name != dependency.name
                        && std.record.has_field
                          dependency.name
                          (recipe.runtime_closure_set [other])
                      )
                      package.deps.runtime
                  )
              in
              std.string.join " " via
            )
            direct_runtime_inputs
        in
        let closure = {
          name = "check-runtime-closure-%{recipe_name}",
          tag = "RootfsClosure",
          config = {},
          inputs = { root = package },
        }
        in
        {
          name = "check-runtime-%{recipe_name}",
          tag = "Sandbox",
          config = {
            script_config = {
              name = "runtime-%{recipe_name}",
              subject = package.name,
              runtime_dependencies = direct_runtime_names,
              redundant_runtime_dependencies = redundant_runtime_dependency_names,
              suppress = [],
            },
            steps = [
              {
                name = "check_runtime_closure",
                run_as = "root",
                cwd = "@{out}",
                argv = ["@{script}"],
              },
            ],
          },
          inputs =
            direct_runtime_inputs
            & {
              _rootfs = pkgs.oci_buildpack_deps_rootfs,
              _subject = package,
              _target = closure,
              script = check_source,
            },
        }
      )
      (std.record.fields runtime_roots)
  in

  let runtime_closure_reports = {
    name = "runtime-closure-check-reports",
    tag = "Bundle",
    config = {},
    inputs = recipe.numbered_inputs runtime_closure_checks,
  }
  in

  # Findings are data: the audit always publishes its complete summary and a
  # machine-readable status. Only the following gate turns that status into a
  # failing goal, so cancellation cannot discard the useful audit object.
  let runtime_closure_audit = {
    name = "runtime-closure-audit",
    tag = "Sandbox",
    config = {
      steps = [
        {
          name = "audit",
          run_as = "root",
          cwd = "@{out}",
          argv = ["@{script}"],
        },
      ],
    },
    inputs = {
      _rootfs = pkgs.oci_buildpack_deps_rootfs,
      allowlist = runtime_deps_allowlist_source,
      reports = runtime_closure_reports,
      script = runtime_closure_audit_source,
    },
  }
  in

  let test_runtime_closures = {
    name = "test-runtime-closures",
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
      _rootfs = pkgs.oci_buildpack_deps_rootfs,
      audit = runtime_closure_audit,
      script = runtime_closure_gate_source,
    },
  }
  in

  # Gen1 recipes intentionally predate the ordinary package dependency model:
  # many provide an explicit `_rootfs` and have no `deps` field, so they cannot
  # yet be checked as isolated package runtime closures. Check only the four
  # canonical bootstrap environments instead of every derived package build
  # rootfs. Ordinary build rootfs trees are unions of package runtime closures
  # and are therefore covered more strictly by `test_runtime_closures`.
  let bootstrap_checks = [
    mk_rootfs_check
      pkgs.oci_buildpack_deps_rootfs.name
      pkgs.oci_buildpack_deps_rootfs,
    mk_rootfs_check
      pkgs.glibc_bootstrap_rootfs.name
      pkgs.glibc_bootstrap_rootfs,
    mk_rootfs_check
      "gen1-toolchain-rootfs"
      (recipe.gen1_toolchain_rootfs pkgs "gen1-toolchain-rootfs" []),
    mk_rootfs_check
      "bootstrap-toolchain-rootfs"
      (recipe.bootstrap_toolchain_rootfs pkgs "bootstrap-toolchain-rootfs" []),
  ]
  in

  let test_bootstrap_rootfs =
    mk_check_gate
      "test-bootstrap-rootfs"
      "bootstrap-rootfs-check-reports"
      bootstrap_checks
  in

  let test_rootfs = mk_image_check "qemu" pkgs.qemu_rootfs {} in

  let test_gnome_rootfs =
    mk_image_check
      "qemu-gnome"
      pkgs.qemu_gnome_rootfs
      {
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

  let test_weston_rootfs =
    mk_image_check
      "qemu-weston"
      pkgs.qemu_weston_rootfs
      {
        check_graphics = "true",
      }
  in

  let test_initrd_rootfs =
    mk_rootfs_check pkgs.initrd_rootfs.name pkgs.initrd_rootfs
  in

  let image_checks = [
    test_initrd_rootfs,
    test_rootfs,
    test_weston_rootfs,
    test_gnome_rootfs,
  ]
  in

  let test_image_rootfs =
    mk_check_gate
      "test-image-rootfs"
      "image-rootfs-check-reports"
      image_checks
  in

  # Run every explicit check. The artifact-only world is a separate target.
  let test_all = {
    name = "test-all",
    tag = "Group",
    config = {},
    inputs =
      recipe.numbered_inputs [
        test_host_bundles,
        test_runtime_closures,
        test_bootstrap_rootfs,
        test_image_rootfs,
        test_final_toolchain,
      ],
  }
  in

  {
    include [
      test_host_bundles,
      test_final_toolchain,
      test_runtime_closures,
      test_bootstrap_rootfs,
      test_initrd_rootfs,
      test_rootfs,
      test_weston_rootfs,
      test_gnome_rootfs,
      test_image_rootfs,
      test_all,
    ],
  }
