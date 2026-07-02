fun pkgs =>
let buildscript_autotools = {
  name = "buildscript-autotools",
  tag = "Source",
  object_hash = import "autotools.sh.fsobj-hash" as 'Text,
  origin = {
    tag = "RecipePath",
    path = "synthetic/autotools.sh",
  },
}
in
let buildscript_common = {
  name = "buildscript-synthetic-common",
  tag = "Source",
  object_hash = import "common.sh.fsobj-hash" as 'Text,
  origin = {
    tag = "RecipePath",
    path = "synthetic/common.sh",
  },
}
in
let buildscript_gnu_make = {
  name = "buildscript-gnu-make",
  tag = "Source",
  object_hash = import "gnu-make.sh.fsobj-hash" as 'Text,
  origin = {
    tag = "RecipePath",
    path = "synthetic/gnu-make.sh",
  },
}
in
let buildscript_meson = {
  name = "buildscript-meson",
  tag = "Source",
  object_hash = import "meson.sh.fsobj-hash" as 'Text,
  origin = {
    tag = "RecipePath",
    path = "synthetic/meson.sh",
  },
}
in
let buildscript_perl_module = {
  name = "buildscript-perl-module",
  tag = "Source",
  object_hash = import "perl-module.sh.fsobj-hash" as 'Text,
  origin = {
    tag = "RecipePath",
    path = "synthetic/perl-module.sh",
  },
}
in
let record_get_or = fun field =>
  fun fallback =>
    fun record =>
      if std.record.has_field field record then
        std.record.get field record
      else
        fallback
in
let record_replace = fun field =>
  fun value =>
    fun record =>
      std.record.insert
        field
        value
        (
          if std.record.has_field field record then
            std.record.remove field record
          else
            record
        )
in
let fail = fun message =>
  std.record.get message {}
in
let pad3 = fun n =>
  let digits = std.string.from_number n in
  if n < 10 then
    "00" ++ digits
  else if n < 100 then
    "0" ++ digits
  else
    digits
in
let numbered_inputs = fun inputs =>
  std.record.from_array (
    std.array.map_with_index
      (fun idx =>
        fun input =>
          {
            field = "n" ++ pad3 idx,
            value = input,
          }
      )
      inputs
  )
in
let deps_or_empty = fun node =>
  record_get_or "deps" { build = [], runtime = [] } node
in
let runtime_deps_or_empty = fun node =>
  record_get_or "runtime" [] (deps_or_empty node)
in
let build_deps_or_empty = fun node =>
  record_get_or "build" [] (deps_or_empty node)
in
let dependency_cycle_error = fun stack =>
  fun name =>
    fail (
      "runtime dependency cycle: "
      ++ std.string.join " -> " (stack @ [name])
    )
in
let runtime_closure_set = fun roots =>
  let rec visit = fun visiting =>
    fun visited =>
      fun stack =>
        fun node =>
          let name = node.name in
          if std.record.has_field name visiting then
            dependency_cycle_error stack name
          else if std.record.has_field name visited then
            visited
          else
            let visiting_with_node = std.record.insert name true visiting in
            let visited_with_deps =
              std.array.fold_left
                (fun acc =>
                  fun dep =>
                    visit visiting_with_node acc (stack @ [name]) dep
                )
                visited
                (runtime_deps_or_empty node)
            in
            std.record.insert name node visited_with_deps
  in
  std.array.fold_left
    (fun acc => fun node => visit {} acc [] node)
    {}
    roots
in
let sorted_closure_nodes = fun closure_set =>
  std.array.map
    (fun name => std.record.get name closure_set)
    (std.array.sort std.string.compare (std.record.fields closure_set))
in
let common_native_package_default_build_deps = [
  pkgs.linux_headers,
  pkgs.glibc,
  pkgs.binutils,
  pkgs.gcc,
  pkgs.bash,
  pkgs.make,
  pkgs.coreutils,
  pkgs.gawk,
  pkgs.sed,
  pkgs.grep,
  pkgs.tar,
  pkgs.gzip,
  pkgs.bzip2,
  pkgs.xz,
  pkgs.patch,
  pkgs.findutils,
  pkgs.diffutils,
]
in
let autotools_package_default_build_deps =
  common_native_package_default_build_deps
  @ [
    pkgs.autoconf,
    pkgs.m4,
    pkgs.perl,
  ]
in
let makefile_package_default_build_deps = common_native_package_default_build_deps
in
let meson_package_default_build_deps =
  common_native_package_default_build_deps
  @ [
    pkgs.pkgconf,
    pkgs.python,
  ]
in
let perl_module_package_default_build_deps =
  common_native_package_default_build_deps
  @ [
    pkgs.perl,
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
    let build_base = pkgs.base_filesystem in
    let build_deps = default_build_deps @ build_deps_or_empty node in
    let closure_nodes = sorted_closure_nodes (runtime_closure_set build_deps) in
    if std.array.length closure_nodes == 0 then
      build_base
    else
      {
        name = node.name ++ "-build-rootfs",
        tag = "TreeMerge",
        config = {},
        inputs = numbered_inputs ([build_base] @ closure_nodes),
      }
in
let rootfs_closure_for = fun node =>
  let root_fields = std.array.sort std.string.compare (std.record.fields node.inputs) in
  let roots = std.array.map (fun field => std.record.get field node.inputs) root_fields in
  if std.array.length roots == 0 then
    fail ("RootfsClosure '" ++ node.name ++ "' must have at least one input")
  else
    {
      name = node.name,
      tag = "TreeMerge",
      config = {},
      inputs = numbered_inputs ([pkgs.base_filesystem] @ sorted_closure_nodes (runtime_closure_set roots)),
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
          std.array.sort
            std.string.compare
            (
              std.array.filter
                (fun name => std.string.is_match "^patch" name)
                (std.record.fields inputs)
            )
        )
    )
in
let synthetic_step_env = fun node => {
  BOBR_SOURCE_INPUT = "@{source}",
  BOBR_SOURCE_DIR = "@{build}/source",
  BOBR_SYNTHETIC_COMMON = "@{synthetic_common}",
  BOBR_PATCH_INPUTS = synthetic_patch_input_paths node.inputs,
}
in
let synthetic_prepare_step = fun step_env => {
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
let lower_autotools_node = fun node =>
  let node_config = node.config in
  let source_root_expr = synthetic_source_root_expr node_config in
  let pre_configure_steps =
    normalize_hook_steps node_config "pre_configure" source_root_expr
  in
  let post_install_steps =
    normalize_hook_steps node_config "post_install" "@{out}"
  in
  let lowered_script_config =
    let with_configure_args =
      if std.record.has_field "configure_args" node_config then
        { configure_args = node_config.configure_args }
      else
        {}
    in
    let with_make_args =
      if std.record.has_field "make_args" node_config then
        std.record.insert "make_args" node_config.make_args with_configure_args
      else
        with_configure_args
    in
    let with_env =
      if std.record.has_field "env" node_config then
        std.record.insert "env" node_config.env with_make_args
      else
        with_make_args
    in
    let with_source_subdir =
      if std.record.has_field "source_subdir" node_config then
        std.record.insert "source_subdir" node_config.source_subdir with_env
      else
        with_env
    in
    let with_python_modules =
      if std.record.has_field "python_modules" node_config then
        std.record.insert "python_modules" node_config.python_modules with_source_subdir
      else
        with_source_subdir
    in
    if record_get_or "in-tree" false node_config then
      std.record.insert "in-tree" "true" with_python_modules
    else
      with_python_modules
  in
  let autotools_step_env = synthetic_step_env node
  in
  {
    name = node.name,
    tag = "Sandbox",
    config = {
      steps =
        [synthetic_prepare_step autotools_step_env]
        @ pre_configure_steps
        @ [
          {
            name = "bobr_configure",
            run_as = "build-user",
            cwd = "@{build}",
            argv = ["@{script}", "configure"],
            env = autotools_step_env,
          },
          {
            name = "bobr_build",
            run_as = "build-user",
            cwd = "@{build}",
            argv = ["@{script}", "build"],
            env = autotools_step_env,
          },
          {
            name = "bobr_install",
            run_as = "root",
            cwd = "@{build}",
            argv = ["@{script}", "install"],
            env = autotools_step_env,
          },
        ]
        @ post_install_steps,
      script_config = lowered_script_config,
    },
    inputs =
      synthetic_inputs buildscript_autotools node.inputs,
  }
in
let lower_autotools_package_node = fun node =>
  let build_rootfs = build_rootfs_for autotools_package_default_build_deps node in
  let package_inputs =
    record_replace
      "_rootfs"
      build_rootfs
      node.inputs
  in
  lower_autotools_node (
    record_replace
      "inputs"
      package_inputs
      (record_replace "tag" "AutotoolsRootfs" node)
  )
in
let lower_makefile_node = fun node =>
  let node_config = node.config in
  let source_root_expr = synthetic_source_root_expr node_config in
  let pre_build_steps =
    normalize_hook_steps node_config "pre_build" source_root_expr
  in
  let post_install_steps =
    normalize_hook_steps node_config "post_install" "@{out}"
  in
  let lowered_script_config =
    let with_make_args =
      if std.record.has_field "make_args" node_config then
        { make_args = node_config.make_args }
      else
        {}
    in
    let with_env =
      if std.record.has_field "env" node_config then
        std.record.insert "env" node_config.env with_make_args
      else
        with_make_args
    in
    let with_source_subdir =
      if std.record.has_field "source_subdir" node_config then
        std.record.insert "source_subdir" node_config.source_subdir with_env
      else
        with_env
    in
    if record_get_or "skip_install" false node_config then
      std.record.insert "skip_install" "true" with_source_subdir
    else
      with_source_subdir
  in
  let makefile_step_env = synthetic_step_env node
  in
  {
    name = node.name,
    tag = "Sandbox",
    config = {
      steps =
        [synthetic_prepare_step makefile_step_env]
        @ pre_build_steps
        @ [
          {
            name = "bobr_build",
            run_as = "build-user",
            cwd = "@{build}",
            argv = ["@{script}", "build"],
            env = makefile_step_env,
          },
          {
            name = "bobr_install",
            run_as = "root",
            cwd = "@{build}",
            argv = ["@{script}", "install"],
            env = makefile_step_env,
          },
        ]
        @ post_install_steps,
      script_config = lowered_script_config,
    },
    inputs =
      synthetic_inputs buildscript_gnu_make node.inputs,
  }
in
let lower_meson_node = fun node =>
  let node_config = node.config in
  let source_root_expr = synthetic_source_root_expr node_config in
  let pre_configure_steps =
    normalize_hook_steps node_config "pre_configure" source_root_expr
  in
  let post_install_steps =
    normalize_hook_steps node_config "post_install" "@{build}"
  in
  let lowered_script_config =
    let with_setup_args =
      if std.record.has_field "setup_args" node_config then
        { setup_args = node_config.setup_args }
      else
        {}
    in
    let with_env =
      if std.record.has_field "env" node_config then
        std.record.insert "env" node_config.env with_setup_args
      else
        with_setup_args
    in
    let with_source_subdir =
      if std.record.has_field "source_subdir" node_config then
        std.record.insert "source_subdir" node_config.source_subdir with_env
      else
        with_env
    in
    with_source_subdir
  in
  let meson_step_env = synthetic_step_env node
  in
  {
    name = node.name,
    tag = "Sandbox",
    config = {
      steps =
        [synthetic_prepare_step meson_step_env]
        @ pre_configure_steps
        @ [
          {
            name = "bobr_configure",
            run_as = "build-user",
            cwd = "@{build}",
            argv = ["@{script}", "configure"],
            env = meson_step_env,
          },
          {
            name = "bobr_build",
            run_as = "build-user",
            cwd = "@{build}",
            argv = ["@{script}", "build"],
            env = meson_step_env,
          },
          {
            name = "bobr_install",
            run_as = "root",
            cwd = "@{build}",
            argv = ["@{script}", "install"],
            env = meson_step_env,
          },
        ]
        @ post_install_steps,
      script_config = lowered_script_config,
    },
    inputs =
      synthetic_inputs buildscript_meson node.inputs,
  }
in
let lower_perl_module_node = fun node =>
  let node_config = node.config in
  let source_root_expr = synthetic_source_root_expr node_config in
  let pre_configure_steps =
    normalize_hook_steps node_config "pre_configure" source_root_expr
  in
  let post_install_steps =
    normalize_hook_steps node_config "post_install" "@{out}"
  in
  let lowered_script_config =
    let with_perl_args =
      if std.record.has_field "perl_args" node_config then
        { perl_args = node_config.perl_args }
      else
        {}
    in
    let with_make_args =
      if std.record.has_field "make_args" node_config then
        std.record.insert "make_args" node_config.make_args with_perl_args
      else
        with_perl_args
    in
    let with_env =
      if std.record.has_field "env" node_config then
        std.record.insert "env" node_config.env with_make_args
      else
        with_make_args
    in
    if std.record.has_field "source_subdir" node_config then
      std.record.insert "source_subdir" node_config.source_subdir with_env
    else
      with_env
  in
  let perl_module_step_env = synthetic_step_env node
  in
  {
    name = node.name,
    tag = "Sandbox",
    config = {
      steps =
        [synthetic_prepare_step perl_module_step_env]
        @ pre_configure_steps
        @ [
          {
            name = "bobr_configure",
            run_as = "build-user",
            cwd = "@{build}",
            argv = ["@{script}", "configure"],
            env = perl_module_step_env,
          },
          {
            name = "bobr_build",
            run_as = "build-user",
            cwd = "@{build}",
            argv = ["@{script}", "build"],
            env = perl_module_step_env,
          },
          {
            name = "bobr_install",
            run_as = "root",
            cwd = "@{build}",
            argv = ["@{script}", "install"],
            env = perl_module_step_env,
          },
        ]
        @ post_install_steps,
      script_config = lowered_script_config,
    },
    inputs =
      synthetic_inputs buildscript_perl_module node.inputs,
  }
in
let lower_makefile_package_node = fun node =>
  let build_rootfs = build_rootfs_for makefile_package_default_build_deps node in
  let package_inputs =
    record_replace
      "_rootfs"
      build_rootfs
      node.inputs
  in
  lower_makefile_node (
    record_replace
      "inputs"
      package_inputs
      (record_replace "tag" "MakefileRootfs" node)
  )
in
let lower_meson_package_node = fun node =>
  let build_rootfs = build_rootfs_for meson_package_default_build_deps node in
  let package_inputs =
    record_replace
      "_rootfs"
      build_rootfs
      node.inputs
  in
  lower_meson_node (
    record_replace
      "inputs"
      package_inputs
      (record_replace "tag" "MesonRootfs" node)
  )
in
let lower_perl_module_package_node = fun node =>
  let build_rootfs = build_rootfs_for perl_module_package_default_build_deps node in
  let package_inputs =
    record_replace
      "_rootfs"
      build_rootfs
      node.inputs
  in
  lower_perl_module_node (
    record_replace
      "inputs"
      package_inputs
      (record_replace "tag" "PerlModuleRootfs" node)
  )
in
let lower_sandbox_build_node = fun node =>
  let build_rootfs = build_rootfs_for sandbox_build_default_build_deps node in
  let package_inputs =
    record_replace
      "_rootfs"
      build_rootfs
      node.inputs
  in
  record_replace
    "inputs"
    package_inputs
    (record_replace "tag" "Sandbox" node)
in
let lower_sandbox_build_rootfs_node = fun node =>
  record_replace "tag" "Sandbox" node
in
{
  "RootfsClosure" = rootfs_closure_for,
  "Autotools" = lower_autotools_package_node,
  "Makefile" = lower_makefile_package_node,
  "Meson" = lower_meson_package_node,
  "PerlModule" = lower_perl_module_package_node,
  "SandboxBuild" = lower_sandbox_build_node,
  "AutotoolsRootfs" = lower_autotools_node,
  "MakefileRootfs" = lower_makefile_node,
  "MesonRootfs" = lower_meson_node,
  "PerlModuleRootfs" = lower_perl_module_node,
  "SandboxBuildRootfs" = lower_sandbox_build_rootfs_node,
}
