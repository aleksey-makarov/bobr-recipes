# Synthetic-tag lowering registry: maps each synthetic recipe tag to the
# function that lowers it to the low-level builder graph. The scripted build
# families (autotools/makefile/meson/perl/python/cargo) share one generic
# generator, `lower_synthetic_with`, parameterized by a row of
# `synthetic_families`: which hook field precedes the scripted phases, the
# phases themselves, which config fields pass through to `script_config`, and
# which boolean flags lower to the string "true" (script_config supports only
# string leaves).
let cargo = import "../cargo.ncl" in
let br = import "../build-rootfs.ncl" in
fun pkgs =>
  # One `Source` node per synthetic build script. The `.fsobj-hash` sidecar
  # import must stay a literal path at each call site (Nickel imports cannot
  # be computed), so the hash is passed in.
  let mk_buildscript = fun slug =>
    fun file_stem =>
      fun hash =>
        {
          name = "buildscript-%{slug}",
          tag = "Source",
          object_hash = hash,
          origin = {
            tag = "RecipePath",
            path = "synthetic/%{file_stem}.sh",
          },
        }
  in
  let buildscript_autotools_install =
    mk_buildscript "autotools-install" "autotools-install" (import "autotools-install.sh.fsobj-hash" as 'Text)
  in
  let buildscript_autotools_stage_install =
    mk_buildscript "autotools-stage-install" "autotools-stage-install" (import "autotools-stage-install.sh.fsobj-hash" as 'Text)
  in
  let buildscript_common =
    mk_buildscript "synthetic-common" "common" (import "common.sh.fsobj-hash" as 'Text)
  in
  let buildscript_gnu_make_install =
    mk_buildscript "gnu-make-install" "gnu-make-install" (import "gnu-make-install.sh.fsobj-hash" as 'Text)
  in
  let buildscript_gnu_make_stage_install =
    mk_buildscript "gnu-make-stage-install" "gnu-make-stage-install" (import "gnu-make-stage-install.sh.fsobj-hash" as 'Text)
  in
  let buildscript_meson =
    mk_buildscript "meson" "meson" (import "meson.sh.fsobj-hash" as 'Text)
  in
  let buildscript_perl_module =
    mk_buildscript "perl-module" "perl-module" (import "perl-module.sh.fsobj-hash" as 'Text)
  in
  let buildscript_python_module =
    mk_buildscript "python-module" "python-module" (import "python-module.sh.fsobj-hash" as 'Text)
  in
  let buildscript_cargo =
    mk_buildscript "cargo" "cargo" (import "cargo.sh.fsobj-hash" as 'Text)
  in
  let numbered_inputs = br.numbered_inputs in
  let autotools_package_default_build_deps =
    br.native_build_deps pkgs
    @ [
      pkgs.autoconf,
      pkgs.m4,
      pkgs.perl,
    ]
  in
  let makefile_package_default_build_deps = br.native_build_deps pkgs
  in
  let meson_package_default_build_deps = br.meson_build_deps pkgs
  in
  let perl_module_package_default_build_deps =
    br.native_build_deps pkgs
    @ [
      pkgs.perl,
    ]
  in
  let python_module_package_default_build_deps =
    br.native_build_deps pkgs
    @ [
      pkgs.python,
    ]
  in
  let rust_package_default_build_deps =
    br.native_build_deps pkgs
    @ [
      pkgs.rust_bin,
    ]
  in
  let sandbox_build_default_build_deps = [
    pkgs.bash,
    pkgs.tar,
    pkgs.gzip,
    pkgs.bzip2,
    pkgs.xz,
    pkgs.patch,
  ]
  in
  let build_rootfs_for = fun default_build_deps =>
    fun node =>
      br.build_rootfs_closure
        pkgs
        (node.name ++ "-build-rootfs")
        (default_build_deps @ br.build_deps_or_empty node)
  in
  let rootfs_closure_for = fun node =>
    let root_fields = std.record.fields node.inputs in # already sorted
    let roots = std.array.map (fun field => std.record.get field node.inputs) root_fields in
    if std.array.length roots == 0 then
      std.fail_with "RootfsClosure '%{node.name}' must have at least one input"
    else
      {
        name = node.name,
        tag = "TreeMerge",
        config = {},
        inputs = numbered_inputs ([pkgs.base_filesystem] @ br.sorted_closure_nodes (br.runtime_closure_set roots)),
      }
  in
  let synthetic_source_root_expr = fun node_config =>
    if std.record.has_field "source_subdir" node_config then
      "@{build}/source/" ++ node_config.source_subdir
    else
      "@{build}/source"
  in
  let synthetic_patch_input_paths = fun inputs =>
    std.string.join
      " "
      (
        std.array.map
          (fun name => "@{" ++ name ++ "}")
          (
            # `std.record.fields` is already sorted and `filter` preserves order.
            std.array.filter
              (fun name => std.string.is_match "^patch" name)
              (std.record.fields inputs)
          )
      )
  in
  let synthetic_step_env = fun node =>
    {
      BOBR_SOURCE_INPUT = "@{source}",
      BOBR_SOURCE_DIR = "@{build}/source",
      BOBR_SYNTHETIC_COMMON = "@{synthetic_common}",
      BOBR_PATCH_INPUTS = synthetic_patch_input_paths node.inputs,
    }
  in
  let synthetic_prepare_step = fun step_env =>
    {
      name = "bobr_prepare_source",
      run_as = "build-user",
      cwd = "@{build}",
      argv = ["@{script}", "prepare"],
      env = step_env,
    }
  in
  let synthetic_inputs = fun script =>
    fun inputs =>
      std.record.insert
        "synthetic_common"
        buildscript_common
        (
          std.record.insert
            "script"
            script
            inputs
        )
  in
  let normalize_hook_steps = fun node_config =>
    fun field_name =>
      fun default_cwd =>
        if std.record.has_field field_name node_config then
          let normalize_step = fun step =>
            if std.record.has_field "cwd" step then
              step
            else
              std.record.insert "cwd" default_cwd step
          in
          if std.is_array (std.record.get field_name node_config) then
            std.array.map normalize_step (std.record.get field_name node_config)
          else
            [normalize_step (std.record.get field_name node_config)]
        else
          []
  in
  # --- generic scripted-family lowering --------------------------------------
  let configure_build_install_phases = [
    { name = "bobr_configure", phase = "configure", run_as = "build-user" },
    { name = "bobr_build", phase = "build", run_as = "build-user" },
    { name = "bobr_install", phase = "install", run_as = "root" },
  ]
  in
  let build_install_phases = [
    { name = "bobr_build", phase = "build", run_as = "build-user" },
    { name = "bobr_install", phase = "install", run_as = "root" },
  ]
  in
  let synthetic_families = {
    autotools = {
      pre_hook = "pre_configure",
      phases = configure_build_install_phases,
      passthrough = ["configure_args", "make_args", "env", "source_subdir"],
      flags = ["in-tree"],
      extra_step_env = {},
    },
    makefile = {
      pre_hook = "pre_build",
      phases = build_install_phases,
      passthrough = ["make_args", "env", "source_subdir"],
      flags = ["skip_install"],
      extra_step_env = {},
    },
    meson = {
      pre_hook = "pre_configure",
      phases = configure_build_install_phases,
      passthrough = ["setup_args", "env", "source_subdir"],
      flags = [],
      extra_step_env = {},
    },
    perl_module = {
      pre_hook = "pre_configure",
      phases = configure_build_install_phases,
      passthrough = ["perl_args", "make_args", "env", "source_subdir"],
      flags = [],
      extra_step_env = {},
    },
    python_module = {
      pre_hook = "pre_configure",
      phases = configure_build_install_phases,
      passthrough = ["env", "source_subdir"],
      flags = [],
      extra_step_env = {},
    },
    cargo = {
      pre_hook = null,
      phases =
        [{ name = "bobr_vendor_crates", phase = "vendor", run_as = "build-user" }]
        @ build_install_phases,
      passthrough = ["features", "bins", "env", "source_subdir"],
      flags = ["no_default_features"],
      extra_step_env = { BOBR_CRATES_DIR = "@{crates}" },
    },
  }
  in
  let lower_synthetic_with = fun family =>
    fun builder_tag =>
      fun script_source =>
        fun post_install_cwd =>
          fun node =>
            let node_config = std.record.get_or "config" {} node in
            let pre_steps =
              if family.pre_hook == null then
                []
              else
                normalize_hook_steps node_config family.pre_hook (synthetic_source_root_expr node_config)
            in
            let post_install_steps =
              normalize_hook_steps node_config "post_install" post_install_cwd
            in
            let lowered_script_config =
              let passthrough =
                std.record.filter
                  (fun field _value => std.array.elem field family.passthrough)
                  node_config
              in
              std.array.fold_left
                (fun acc =>
                  fun flag =>
                    if std.record.get_or flag false node_config then
                      std.record.insert flag "true" acc
                    else
                      acc
                )
                passthrough
                family.flags
            in
            let step_env = synthetic_step_env node & family.extra_step_env in
            {
              name = node.name,
              tag = builder_tag,
              config = {
                steps =
                  [synthetic_prepare_step step_env]
                  @ pre_steps
                  @ std.array.map
                    (fun phase =>
                      {
                        name = phase.name,
                        run_as = phase.run_as,
                        cwd = "@{build}",
                        argv = ["@{script}", phase.phase],
                        env = step_env,
                      }
                    )
                    family.phases
                  @ post_install_steps,
                script_config = lowered_script_config,
              },
              inputs =
                synthetic_inputs script_source node.inputs,
            }
  in
  let lower_autotools_install_node =
    lower_synthetic_with synthetic_families.autotools "SandboxInstall" buildscript_autotools_install "/"
  in
  let lower_autotools_stage_install_node =
    lower_synthetic_with synthetic_families.autotools "SandboxInstall" buildscript_autotools_stage_install "/stage"
  in
  # Explicit-rootfs additive-staging autotools builder: runs the synthetic
  # autotools steps but installs into a virgin /stage (autotools-stage-install.sh),
  # which is captured additively and then re-rooted /stage -> / by TreeMove. Use it for
  # explicit-rootfs recipes whose output overlaps the build rootfs (e.g. a
  # toolchain member rebuilt on a rootfs that already carries it), where a plain
  # additive install into / would modify lower-layer files.
  let lower_autotools_stage_rootfs_node = fun node =>
    let staged =
      lower_autotools_stage_install_node
        (std.record.update "name" (node.name ++ "-staged") node)
    in
    {
      name = node.name,
      tag = "TreeMove",
      config = { strip_prefix = "stage" },
      inputs = { tree = staged },
    }
  in
  # The package-level `Autotools` tag builds with the additive SandboxInstall
  # model (install into the overlay root).
  let lower_autotools_package_node = fun node =>
    let build_rootfs = build_rootfs_for autotools_package_default_build_deps node in
    let package_inputs =
      std.record.update
        "_rootfs"
        build_rootfs
        node.inputs
    in
    lower_autotools_install_node (std.record.update "inputs" package_inputs node)
  in
  let lower_makefile_install_node =
    lower_synthetic_with synthetic_families.makefile "SandboxInstall" buildscript_gnu_make_install "/"
  in
  let lower_makefile_stage_install_node =
    lower_synthetic_with synthetic_families.makefile "SandboxInstall" buildscript_gnu_make_stage_install "/stage"
  in
  # Additive-staging Makefile builder (see AutotoolsStageRootfs): runs
  # the synthetic Makefile steps but installs into a virgin /stage, captured
  # additively, then re-rooted /stage -> / by TreeMove. For explicit-rootfs
  # recipes whose output overlaps the build rootfs.
  let lower_makefile_stage_rootfs_node = fun node =>
    let staged =
      lower_makefile_stage_install_node
        (std.record.update "name" (node.name ++ "-staged") node)
    in
    {
      name = node.name,
      tag = "TreeMove",
      config = { strip_prefix = "stage" },
      inputs = { tree = staged },
    }
  in
  # Meson has a single additive builder: no bootstrap/rootfs recipes need the
  # staging model (glib's two-pass build is handled by installing gen1 into a
  # private prefix -- see glib.ncl).
  let lower_meson_node =
    lower_synthetic_with synthetic_families.meson "SandboxInstall" buildscript_meson "/"
  in
  let lower_perl_module_node =
    lower_synthetic_with synthetic_families.perl_module "SandboxInstall" buildscript_perl_module "/"
  in
  let lower_python_module_node =
    lower_synthetic_with synthetic_families.python_module "SandboxInstall" buildscript_python_module "/"
  in
  let lower_cargo_node =
    lower_synthetic_with synthetic_families.cargo "SandboxInstall" buildscript_cargo "/"
  in
  # The package-level `Makefile` tag builds with the additive SandboxInstall
  # model (install into the overlay root). Explicit-rootfs Makefile recipes use
  # the additive-staging `MakefileStageRootfs` tag.
  let lower_makefile_package_node = fun node =>
    let build_rootfs = build_rootfs_for makefile_package_default_build_deps node in
    let package_inputs =
      std.record.update
        "_rootfs"
        build_rootfs
        node.inputs
    in
    lower_makefile_install_node (
      std.record.update
        "inputs"
        package_inputs
        node
    )
  in
  let lower_meson_package_node = fun node =>
    let build_rootfs = build_rootfs_for meson_package_default_build_deps node in
    let package_inputs =
      std.record.update
        "_rootfs"
        build_rootfs
        node.inputs
    in
    lower_meson_node (
      std.record.update
        "inputs"
        package_inputs
        (std.record.update "tag" "Meson" node)
    )
  in
  let lower_perl_module_package_node = fun node =>
    let build_rootfs = build_rootfs_for perl_module_package_default_build_deps node in
    let package_inputs =
      std.record.update
        "_rootfs"
        build_rootfs
        node.inputs
    in
    lower_perl_module_node (
      std.record.update
        "inputs"
        package_inputs
        node
    )
  in
  let lower_python_module_package_node = fun node =>
    let build_rootfs = build_rootfs_for python_module_package_default_build_deps node in
    let package_inputs =
      std.record.update
        "_rootfs"
        build_rootfs
        node.inputs
    in
    lower_python_module_node (
      std.record.update
        "inputs"
        package_inputs
        node
    )
  in
  let lower_cargo_package_node = fun node =>
    let build_rootfs = build_rootfs_for rust_package_default_build_deps node in
    let crates_bundle =
      cargo.vendor_bundle (node.name ++ "-crates") node.cargo_lock
    in
    let package_inputs =
      std.record.update
        "_rootfs"
        build_rootfs
        (std.record.update "crates" crates_bundle node.inputs)
    in
    lower_cargo_node (
      std.record.update
        "inputs"
        package_inputs
        (std.record.update "tag" "CargoRootfs" node)
    )
  in
  # Generic sandbox synthetic builders: derive the build rootfs from
  # sandbox_build_default_build_deps + node.deps.build, then lower to the given
  # low-level tag. `Sandbox` (staging, via SandboxBuild) captures @{out};
  # `SandboxInstall` (additive, via SandboxInstallDeps) installs into the live
  # overlay root (/) and captures only the additions.
  let lower_sandbox_build_with = fun target_tag =>
    fun node =>
      let build_rootfs = build_rootfs_for sandbox_build_default_build_deps node in
      let package_inputs =
        std.record.update
          "_rootfs"
          build_rootfs
          node.inputs
      in
      std.record.update
        "inputs"
        package_inputs
        (std.record.update "tag" target_tag node)
  in
  let lower_sandbox_install_deps_node = lower_sandbox_build_with "SandboxInstall" in
  # Self-rootfs, additive-staging builder: the recipe brings its own steps and
  # `inputs._rootfs` (like the low-level Sandbox) but installs into a virgin
  # `/stage` inside the overlay. It lowers to an additive `SandboxInstall`
  # (captures the /stage additions) wrapped in a `TreeMove` that re-roots the
  # tree at `/stage`, yielding a standalone tree even when the output overlaps
  # the build rootfs (e.g. kernel headers). Recipes using this tag MUST install
  # into `/stage`.
  let lower_sandbox_stage_rootfs_node = fun node =>
    let staged =
      std.record.update
        "tag"
        "SandboxInstall"
        (std.record.update "name" (node.name ++ "-staged") node)
    in
    {
      name = node.name,
      tag = "TreeMove",
      config = { strip_prefix = "stage" },
      inputs = { tree = staged },
    }
  in
  # Deps-derived additive-staging builder: the deps-derived twin of
  # SandboxStageRootfs. Like SandboxInstallDeps it assembles the build rootfs
  # from sandbox_build_default_build_deps + node.deps.build (no hand-rolled
  # `inputs._rootfs`), but installs into a virgin `/stage` and re-roots
  # `/stage` -> `/` via TreeMove -- for bespoke builds whose output overlaps the
  # build rootfs or whose install touches shared paths (a recursive chown, a
  # re-rooted DESTDIR). Recipes using this tag MUST install into `/stage`.
  let lower_sandbox_stage_deps_node = fun node =>
    let installed = lower_sandbox_build_with "SandboxInstall" node in
    let staged = std.record.update "name" (node.name ++ "-staged") installed in
    {
      name = node.name,
      tag = "TreeMove",
      config = { strip_prefix = "stage" },
      inputs = { tree = staged },
    }
  in
  {
    "RootfsClosure" = rootfs_closure_for,
    "Autotools" = lower_autotools_package_node,
    "Makefile" = lower_makefile_package_node,
    "Meson" = lower_meson_package_node,
    "PerlModule" = lower_perl_module_package_node,
    "PythonModule" = lower_python_module_package_node,
    "SandboxInstallDeps" = lower_sandbox_install_deps_node,
    "SandboxStageDeps" = lower_sandbox_stage_deps_node,
    "AutotoolsStageRootfs" = lower_autotools_stage_rootfs_node,
    "MakefileStageRootfs" = lower_makefile_stage_rootfs_node,
    "MesonRootfs" = lower_meson_node,
    "SandboxStageRootfs" = lower_sandbox_stage_rootfs_node,
    "Cargo" = lower_cargo_package_node,
    "CargoRootfs" = lower_cargo_node,
  }
