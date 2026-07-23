let synthetic_registry_for = import "synthetic/registry.ncl" in
let build_rootfs_lib = import "build-rootfs.ncl" in
let lower_node = fun pkgs =>
  fun node =>
    let synthetic_registry = synthetic_registry_for pkgs in
    if std.record.has_field node.tag synthetic_registry then
      (std.record.get node.tag synthetic_registry) node
    else
      node
in
let node_inputs = fun node =>
  if node.tag == "Source" then
    {}
  else
    node.inputs
in
# A readable slug of a node name for request node ids: the name with its
# version segments dropped (any `-`-segment that starts with a digit, which also
# strips the version from `<pkg>-<ver>-build-rootfs`). Purely cosmetic -- node
# ids are request-local labels and never enter a build key.
let node_name_slug = fun name =>
  let kept =
    std.array.filter
      (fun part => part != "" && !std.string.is_match "^[0-9]" part)
      (std.string.split "-" name)
  in
  if std.array.length kept == 0 then name else std.string.join "-" kept
in
let split_libs_name = fun base =>
  let matched = std.string.find "^(.+)-([0-9].*)$" base.name in
  if matched.index == 0 && std.array.length matched.groups == 2 then
    std.array.at 0 matched.groups ++ "-libs-" ++ std.array.at 1 matched.groups
  else
    std.fail_with "recipe.split.libs: base name '%{base.name}' does not match package-version"
in
let split_libs_include = fun globs =>
  if std.is_string globs then
    [globs]
  else
    globs
in
let old_style_input_error = fun node_name =>
  fun slot_name =>
    fun shape =>
      std.fail_with "recipe-lib.to_request: input '%{slot_name}' of node '%{node_name}' uses unsupported old-style %{shape}"
in
let lower_source_origin = fun ctx =>
  fun origin =>
    if origin.tag == "RecipePath" then
      let origin_without_tag =
        std.record.remove "tag" origin
      in
      let origin_without_path =
        std.record.remove "path" origin_without_tag
      in
      origin_without_path
      & {
        tag = "Path",
        path = ctx.recipes_path ++ "/" ++ origin.path,
      }
    else
      origin
in
let default_install_attrs = {
  uid = 0,
  gid = 0,
  directory_mode = 0o755,
  regular_file_mode = 0o644,
  executable_file_mode = 0o755,
}
in
{
  install = {
    root_default_attrs = default_install_attrs,
    fs_tree_root_default_attrs = default_install_attrs,

    rule = fun path => fun attrs => { path, attrs },

    root_default_rule = { path = "**", attrs = default_install_attrs },
    fs_tree_root_default_rule = { path = "**", attrs = default_install_attrs },
  },

  numbered_inputs = build_rootfs_lib.numbered_inputs,

  # First `n` dot-separated components of a version string, e.g.
  # `recipe.version_prefix 2 "2.88.2"` == "2.88" (release branch/series in
  # download URLs) and `recipe.version_prefix 1 "48.1"` == "48" (major-only
  # directories). Replaces per-recipe hand-rolled `branch`/`series` helpers.
  # Fails loudly (array out of bounds) when the version has fewer components.
  version_prefix : Number -> String -> String = fun n =>
    fun version =>
      std.string.join "." (std.array.slice 0 n (std.string.split "." version)),

  # base_filesystem + runtime closure of the native toolchain plus `extra_deps`
  # (no system_rootfs_X). For custom multi-step recipes; the synthetic builders
  # use the same machinery from build-rootfs.ncl. See there for the pieces.
  native_build_rootfs = build_rootfs_lib.native_build_rootfs,
  native_build_deps = build_rootfs_lib.native_build_deps,
  build_rootfs_closure = build_rootfs_lib.build_rootfs_closure,
  # For the final builds of the native userland itself: bootstrap toolchain
  # (gen1 userland + final compiler) closure. Replaces system-rootfs-1.
  bootstrap_toolchain_rootfs = build_rootfs_lib.bootstrap_toolchain_rootfs,
  # For the final compiler builds (glibc/binutils/gcc): fully-gen1 toolchain
  # closure. Replaces system-rootfs-0.
  gen1_toolchain_rootfs = build_rootfs_lib.gen1_toolchain_rootfs,

  split = {
    libs = fun base =>
      fun globs => {
        name = split_libs_name base,
        tag = "TreeSubset",
        config = {
          include = split_libs_include globs,
        },
        inputs = {
          tree = base,
        },
      },
  },

  # Pack a filesystem tree into a reproducible EROFS image. There is no native
  # `ErofsRootfs` builder: this lowers to a `Sandbox` that runs `mkfs.erofs`
  # (from `pkgs.erofs_utils`) over the materialized tree. The build rootfs is the
  # runtime closure of erofs-utils plus a shell; `mk-erofs.sh` supplies the
  # reproducibility flags. The `Sandbox` tag captures the result as a plain-object
  # directory holding a single `erofs-rootfs.erofs` file (the image blob has no
  # meaningful ownership of its own).
  #
  # `args`: { name : String, tree : <fs-tree node to pack> }.
  erofs_image = fun pkgs =>
    fun raw_args =>
      let args = raw_args | { name | String, tree | Dyn } in
      let mkfs_script = {
        name = "%{args.name}-mkfs-script",
        tag = "Source",
        object_hash = import "filesystem/mk-erofs.sh.fsobj-hash" as 'Text,
        origin = {
          tag = "RecipePath",
          path = "filesystem/mk-erofs.sh",
        },
      }
      in
      let build_rootfs = {
        name = "%{args.name}-build-rootfs",
        tag = "RootfsClosure",
        config = {},
        inputs = {
          erofs_utils = pkgs.erofs_utils,
          bash = pkgs.bash,
        },
      }
      in
      {
        name = args.name,
        tag = "Sandbox",
        config = {
          steps = [
            {
              name = "mkfs_erofs",
              run_as = "root",
              cwd = "@{out}",
              argv = ["@{script}"],
            },
          ],
        },
        inputs = {
          _rootfs = build_rootfs,
          _tree = args.tree,
          script = mkfs_script,
        },
      },

  prepare_source_step = {
    name = "prepare_source",
    run_as = "build-user",
    cwd = "@{build}",
    argv = [
      "/bin/sh",
      "-ec",
      m%"
        source_input="@{source}"
        source_dir="@{build}/source"
        marker="@{build}/.bobr-source-prepared"

        if [ -f "$marker" ]; then
          exit 0
        fi

        rm -rf "$source_dir"
        mkdir -p "$source_dir"

        if [ -d "$source_input" ]; then
          tar -C "$source_input" -cf - . | tar -C "$source_dir" -xf -
        elif [ -f "$source_input" ]; then
          tar -C "$source_dir" -xf "$source_input"
          set -- "$source_dir"/*
          if [ "$#" -eq 1 ] && [ -d "$1" ] && [ ! -L "$1" ]; then
            find "$1" -mindepth 1 -maxdepth 1 -exec mv -t "$source_dir" -- {} +
            rmdir "$1"
          fi
        else
          echo "prepare_source: source input is neither file nor directory: $source_input" >&2
          exit 1
        fi

        touch "$marker"
      "%,
    ],
  },

  # Walk the (lowered) graph of `root_node` and collect every node used as the
  # `_rootfs` input of a `Sandbox`/`SandboxInstall` node -- i.e. every build
  # environment in the graph. Nodes are lowered the same way `to_request` lowers
  # them (so synthetic package tags get their derived `_rootfs`), and dedup is by
  # node name. Returns a record `name -> rootfs node`. Used by the rootfs-closure
  # check target to discover what to check without hardcoding a list.
  collect_rootfs_inputs = fun pkgs =>
    fun root_node =>
      let lower = lower_node pkgs in
      let rec go = fun acc =>
        fun node =>
          let ln = lower node in
          if std.record.has_field ln.name acc.visited then
            acc
          else
            let acc = {
              visited = std.record.insert ln.name true acc.visited,
              rootfs =
                if (ln.tag == "Sandbox" || ln.tag == "SandboxInstall")
                && std.record.has_field "_rootfs" ln.inputs
                && !std.record.has_field ln.inputs._rootfs.name acc.rootfs then
                  std.record.insert ln.inputs._rootfs.name ln.inputs._rootfs acc.rootfs
                else
                  acc.rootfs,
            }
            in
            let inputs = node_inputs ln in
            std.array.fold_left
              (fun a => fun slot => go a (std.record.get slot inputs))
              acc
              (std.record.fields inputs)
      in
      (go { visited = {}, rootfs = {} } root_node).rootfs,

  to_request = fun raw_ctx =>
    fun pkgs =>
    fun root_node =>
    let ctx = raw_ctx | { recipes_path | String } in
    let lower = lower_node pkgs in
    let lower_origin = lower_source_origin ctx in
    let rec collect = fun seen =>
      fun node =>
        let lowered_node = lower node in
        if std.record.has_field lowered_node.name seen then
          seen
        else
          let seen_with_node = std.record.insert lowered_node.name lowered_node seen in
          let inputs = node_inputs lowered_node in
          std.array.fold_left
            (fun acc =>
              fun slot_name =>
                let input = std.record.get slot_name inputs in
                let validated_input =
                  if input == null then
                    old_style_input_error lowered_node.name slot_name "null"
                  else if std.is_array input then
                    old_style_input_error lowered_node.name slot_name "array"
                  else
                    input
                in
                collect acc validated_input
            )
            seen_with_node
            (std.record.fields inputs)
    in

    let unique_nodes = collect {} root_node in
    let root_name = root_node.name in
    let other_names =
      # `std.record.fields` already returns names in sorted order, so no explicit
      # sort is needed here (`filter` preserves order). Nickel's `std.array.sort`
      # is quadratic with a huge constant -- a few hundred names take tens of
      # seconds -- so sorting the already-sorted field list dominated request
      # generation.
      std.array.filter
        (fun name => name != root_name)
        (std.record.fields unique_nodes)
    in
    let ordered_names = [root_name] @ other_names in
    let name_to_id =
      std.record.from_array (
        [{ field = root_name, value = "root" }]
        @ std.array.map_with_index
          (fun idx =>
            fun name =>
              {
                field = name,
                value = "n" ++ std.string.from_number idx ++ "_" ++ node_name_slug name,
              }
          )
          other_names
      )
    in
    let input_to_id = fun node_name =>
      fun slot_name =>
        fun input =>
          if input == null then
            old_style_input_error node_name slot_name "null"
          else if std.is_array input then
            old_style_input_error node_name slot_name "array"
          else
            std.record.get input.name name_to_id
    in
    std.record.from_array (
      std.array.map
        (fun name =>
          let node = std.record.get name unique_nodes in
          let node_value =
            if node.tag == "Source" then
              let source_base = {
                name = node.name,
                tag = node.tag,
                object_hash = node.object_hash,
              }
              in
              source_base
              & (
                if std.record.has_field "origin" node then
                  { origin = lower_origin node.origin }
                else
                  {}
              )
            else
              {
                name = node.name,
                tag = node.tag,
                config = node.config,
                inputs =
                  std.record.map
                    (fun slot_name input => input_to_id node.name slot_name input)
                    node.inputs,
              }
          in
          {
            field = std.record.get name name_to_id,
            value = node_value,
          }
        )
        ordered_names
    ),
}
