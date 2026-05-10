let buildscript_autotools = {
  name = "buildscript-autotools",
  tag = "Source",
  object_hash = import "autotools.sh.fsobj-hash" as 'Text,
  origin = {
    type = "path",
    path = "synthetic/autotools.sh",
    mode = "direct",
  },
  meta = {},
}
in
let buildscript_gnu_make = {
  name = "buildscript-gnu-make",
  tag = "Source",
  object_hash = import "gnu-make.sh.fsobj-hash" as 'Text,
  origin = {
    type = "path",
    path = "synthetic/gnu-make.sh",
    mode = "direct",
  },
  meta = {},
}
in
let buildscript_meson = {
  name = "buildscript-meson",
  tag = "Source",
  object_hash = import "meson.sh.fsobj-hash" as 'Text,
  origin = {
    type = "path",
    path = "synthetic/meson.sh",
    mode = "direct",
  },
  meta = {},
}
in
let buildscript_perl_module = {
  name = "buildscript-perl-module",
  tag = "Source",
  object_hash = import "perl-module.sh.fsobj-hash" as 'Text,
  origin = {
    type = "path",
    path = "synthetic/perl-module.sh",
    mode = "direct",
  },
  meta = {},
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
let synthetic_source_root_expr = fun node_config =>
  if std.record.has_field "source_subdir" node_config then
    "@{source}/" ++ node_config.source_subdir
  else
    "@{source}"
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
  fun lowered_tag =>
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
  let autotools_step_env = {
    MBUILD_SOURCE_DIR = "@{source}",
  }
  in
  {
    name = node.name,
    tag = lowered_tag,
    config = (
      {
        steps =
          pre_configure_steps
          @ [
            {
              name = "configure",
              run_as = "build-user",
              cwd = "@{build}",
              argv = ["@{script}", "configure"],
              env = autotools_step_env,
            },
            {
              name = "build",
              run_as = "build-user",
              cwd = "@{build}",
              argv = ["@{script}", "build"],
              env = autotools_step_env,
            },
            {
              name = "install",
              run_as = "root",
              cwd = "@{build}",
              argv = ["@{script}", "install"],
              env = autotools_step_env,
            },
          ]
          @ post_install_steps,
        script_config = lowered_script_config,
      }
      & (
        if lowered_tag != "Sandbox" && std.record.has_field "install" node_config then
          { install = node_config.install }
        else
          {}
      )
    ),
    inputs =
      std.record.insert
        "script"
        buildscript_autotools
        node.inputs,
  }
in
let lower_binary_autotools_node = fun node => lower_autotools_node node "Binary" in
let lower_container_autotools_node = fun node => lower_autotools_node node "Container" in
let lower_sandbox_autotools_node = fun node => lower_autotools_node node "Sandbox" in
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
  let makefile_step_env = {
    MBUILD_SOURCE_DIR = source_root_expr,
  }
  in
  {
    name = node.name,
    tag = "Binary",
    config = (
      {
        steps =
          pre_build_steps
          @ [
            {
              name = "build",
              run_as = "build-user",
              cwd = source_root_expr,
              argv = ["@{script}", "build"],
              env = makefile_step_env,
            },
            {
              name = "install",
              run_as = "root",
              cwd = source_root_expr,
              argv = ["@{script}", "install"],
              env = makefile_step_env,
            },
          ]
          @ post_install_steps,
        script_config = lowered_script_config,
      }
      & (
        if std.record.has_field "install" node_config then
          { install = node_config.install }
        else
          {}
      )
    ),
    inputs =
      std.record.insert
        "script"
        buildscript_gnu_make
        node.inputs,
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
    if std.record.has_field "build_dir" node_config then
      std.record.insert "build_dir" node_config.build_dir with_source_subdir
    else
      with_source_subdir
  in
  let meson_step_env = {
    MBUILD_SOURCE_DIR = "@{source}",
  }
  in
  {
    name = node.name,
    tag = "Binary",
    config = (
      {
        steps =
          pre_configure_steps
          @ [
            {
              name = "configure",
              run_as = "build-user",
              cwd = "@{build}",
              argv = ["@{script}", "configure"],
              env = meson_step_env,
            },
            {
              name = "build",
              run_as = "build-user",
              cwd = "@{build}",
              argv = ["@{script}", "build"],
              env = meson_step_env,
            },
            {
              name = "install",
              run_as = "root",
              cwd = "@{build}",
              argv = ["@{script}", "install"],
              env = meson_step_env,
            },
          ]
          @ post_install_steps,
        script_config = lowered_script_config,
      }
      & (
        if std.record.has_field "install" node_config then
          { install = node_config.install }
        else
          {}
      )
    ),
    inputs =
      std.record.insert
        "script"
        buildscript_meson
        node.inputs,
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
  let perl_module_step_env = {
    MBUILD_SOURCE_DIR = "@{source}",
  }
  in
  {
    name = node.name,
    tag = "Binary",
    config = (
      {
        steps =
          pre_configure_steps
          @ [
            {
              name = "configure",
              run_as = "build-user",
              cwd = "@{build}",
              argv = ["@{script}", "configure"],
              env = perl_module_step_env,
            },
            {
              name = "build",
              run_as = "build-user",
              cwd = "@{build}",
              argv = ["@{script}", "build"],
              env = perl_module_step_env,
            },
            {
              name = "install",
              run_as = "root",
              cwd = "@{build}",
              argv = ["@{script}", "install"],
              env = perl_module_step_env,
            },
          ]
          @ post_install_steps,
        script_config = lowered_script_config,
      }
      & (
        if std.record.has_field "install" node_config then
          { install = node_config.install }
        else
          {}
      )
    ),
    inputs =
      std.record.insert
        "script"
        buildscript_perl_module
        node.inputs,
  }
in
{
  "Autotools" = lower_binary_autotools_node,
  "AutotoolsContainer" = lower_container_autotools_node,
  "AutotoolsSandbox" = lower_sandbox_autotools_node,
  "Makefile" = lower_makefile_node,
  "Meson" = lower_meson_node,
  "PerlModule" = lower_perl_module_node,
}
