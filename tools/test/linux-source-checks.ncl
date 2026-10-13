# Test both explicit kernel recipes together; never export the recursive set.
let recipe = import "../../recipe-lib.ncl" in
let package_set = import "../../bobrpkgs.ncl" in
let original = package_set [] in
let archive = original.linux_src in
let changed_hash = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" in
let replacement_hash = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb" in
let fixture_origin = { tag = "Http", url = "https://example.invalid/kernel-fixture.tar.xz" } in
let wire = fun source =>
  { name = source.name, tag = source.tag, object_hash = source.object_hash }
  & (if std.record.has_field "origin" source then { origin = source.origin } else {})
in
let replacement = fun label =>
  fun version =>
    {
      include version,
      name = "fixture-linux-%{label}",
      tag = "Source",
      object_hash = replacement_hash,
      origin = fixture_origin,
    }
in
let alternate = replacement "alternate" "8.7.6" in
let source_fields = archive & { version = "9.8.7", object_hash = changed_hash } in
let fixture_options = { DRM_VIRTIO_GPU = 'n, USB_STORAGE = 'm, HZ = 250, LOCALVERSION = "-fixture" } in
let tiny_options = { PRINTK = 'n, LOCALVERSION = "-tiny-fixture" } in
let fixture_lines = ["# CONFIG_DRM_VIRTIO_GPU is not set", "CONFIG_USB_STORAGE=m", "CONFIG_HZ=250", "CONFIG_LOCALVERSION=\"-fixture\""] in
let tiny_lines = ["# CONFIG_PRINTK is not set", "CONFIG_LOCALVERSION=\"-tiny-fixture\""] in
let builders = ["linux", "linux_tiny", "linux_headers", "linux_headers_gen1", "gen_init_cpio"] in
let kernels = [
  { attr = "linux", base = "defconfig", modules = "CONFIG_MODULES=y" },
  { attr = "linux_tiny", base = "tinyconfig", modules = "# CONFIG_MODULES is not set" },
]
in
let attrs = ["linux_src"] @ builders @ ["linux_modules", "linux_bzimage", "linux_tiny_bzimage"] in
let kernel_tree = {
  name = "fixture-kernel-tree",
  tag = "Source",
  object_hash = "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
  # Source metadata is used for the modules name, not serialized as content.
  inputs = { source = alternate },
}
in
let common_cases = [
  { label = "default_both_kernels", overlays = [] },
  { label = "source_fields", source = source_fields, expected_url = "https://www.kernel.org/pub/linux/kernel/v9.x/linux-9.8.7.tar.xz", overlays = [ fun _final => fun prev => { linux_src = prev.linux_src & { version = "9.8.7", object_hash = changed_hash } }] },
  { label = "source_hash", source = archive & { object_hash = changed_hash }, overlays = [ fun _final => fun prev => { linux_src = prev.linux_src & { object_hash = changed_hash } }] },
  { label = "source_origin", source = archive & { origin | force = fixture_origin }, overlays = [ fun _final => fun prev => { linux_src = prev.linux_src & { origin | force = fixture_origin } }] },
  { label = "source_replacement", source = alternate, overlays = [ fun _final => fun _prev => { linux_src = alternate }] },
  { label = "source_without_origin", source = std.record.remove "origin" alternate, overlays = [ fun _final => fun _prev => { linux_src = std.record.remove "origin" alternate }] },
  {
    label = "configured_linux",
    options = { linux = fixture_options },
    lines = { linux = fixture_lines },
    overlays = [ fun _final => fun prev => { linux = prev.linux & { config_options = fixture_options } }],
  },
  {
    label = "configured_tiny",
    options = { linux_tiny = fixture_options },
    lines = { linux_tiny = fixture_lines },
    overlays = [ fun _final => fun prev => { linux_tiny = prev.linux_tiny & { config_options = fixture_options } }],
  },
  {
    label = "independent_kernel_configs",
    options = { linux = fixture_options, linux_tiny = tiny_options },
    lines = { linux = fixture_lines, linux_tiny = tiny_lines },
    overlays = [
      fun _final =>
        fun prev =>
          {
            linux = prev.linux & { config_options = fixture_options },
            linux_tiny = prev.linux_tiny & { config_options = tiny_options },
          }
    ],
  },
  {
    label = "combined_source_and_kernel_input",
    source = source_fields,
    sources = { linux = alternate },
    overlays = [
      fun _final =>
        fun prev =>
          {
            linux_src = prev.linux_src & { version = "9.8.7", object_hash = changed_hash },
            linux = prev.linux & { inputs.source | force = alternate },
          }
    ],
  },
  {
    label = "combined_source_and_tiny_input",
    source = source_fields,
    sources = { linux_tiny = alternate },
    overlays = [
      fun _final =>
        fun prev =>
          {
            linux_src = prev.linux_src & { version = "9.8.7", object_hash = changed_hash },
            linux_tiny = prev.linux_tiny & { inputs.source | force = alternate },
          }
    ],
  },
  { label = "modules_tree", modules_tree = kernel_tree, overlays = [ fun _final => fun prev => { linux_modules = prev.linux_modules & { inputs.tree | force = kernel_tree } }] },
  { label = "image_tree", image_tree = kernel_tree, overlays = [ fun _final => fun prev => { linux_bzimage = prev.linux_bzimage & { inputs.input | force = kernel_tree } }] },
  { label = "tiny_image_tree", tiny_image_tree = kernel_tree, overlays = [ fun _final => fun prev => { linux_tiny_bzimage = prev.linux_tiny_bzimage & { inputs.input | force = kernel_tree } }] },
]
in
let input_cases =
  std.array.flat_map
    (fun attr =>
      std.array.map
        (fun same_version =>
          let input = replacement attr (if same_version then archive.version else "8.7.6") in
          {
            label = "%{attr}_input%{if same_version then "_same_version" else ""}",
            sources = std.record.from_array [{ field = attr, value = input }],
            overlays = [
              fun _final =>
                fun prev =>
                  std.record.from_array [
                    {
                      field = attr,
                      value = std.record.get attr prev & { inputs.source | force = input },
                    }
                  ]
            ],
          }
        )
        [ false, true ]
    )
    builders
in
let cases = common_cases @ input_cases in
let actual_builder = fun graph =>
  let rec go = fun id =>
    let node = std.record.get id graph.nodes in
    if std.record.has_field "source" node.inputs then node else go node.inputs.tree
  in go
in
{
  count = std.array.length cases,
  run = fun recipes_path =>
    fun index =>
      let spec = std.array.at index cases in
      let pkgs = package_set spec.overlays in
      let expected_archive = std.record.get_or "source" archive spec in
      let sources = std.record.get_or "sources" {} spec in
      let expected_kernel = std.record.get_or "linux" expected_archive sources in
      let expected_sources = {
        linux = expected_kernel,
        linux_tiny = std.record.get_or "linux_tiny" expected_archive sources,
        linux_headers = std.record.get_or "linux_headers" expected_archive sources,
        linux_headers_gen1 = std.record.get_or "linux_headers_gen1" expected_archive sources,
        gen_init_cpio = std.record.get_or "gen_init_cpio" expected_kernel sources,
      }
      in
      let names = {
        linux = "linux-",
        linux_tiny = "linux-tiny-",
        linux_headers = "linux-headers-",
        linux_headers_gen1 = "linux-headers-gen1-",
        gen_init_cpio = "gen-init-cpio-",
      }
      in
      let graph =
        recipe.to_request_goals
          { include recipes_path }
          pkgs
          (std.array.map (fun attr => std.record.get attr pkgs) attrs)
      in
      let nodes =
        std.record.from_array (
          std.array.map_with_index
            (fun position => fun attr => { field = attr, value = std.record.get (std.array.at position graph.goals) graph.nodes })
            attrs
        )
      in
      let builder_checks =
        std.array.map_with_index
          (fun position =>
            fun attr =>
              let node = std.record.get attr pkgs in
              let expected = std.record.get attr expected_sources in
              let lowered = actual_builder graph (std.array.at (position + 1) graph.goals) in
              {
                check = attr,
                correct =
                  !std.record.has_field "version" node
                  && !std.record.has_field "source_object_hash" node
                  && !std.record.has_field "use_tinyconfig" node
                  && node.name == std.record.get attr names
                  ++ expected.version
                  && node.inputs.source.version == expected.version
                  && wire node.inputs.source == wire expected
                  && std.record.get lowered.inputs.source graph.nodes == wire expected
                  && (
                    if attr == "linux_headers" || attr == "linux_headers_gen1" || attr == "gen_init_cpio" then
                      node.config == (std.record.get attr original).config
                    else
                      true
                  )
                  && (
                    if attr == "linux" || attr == "linux_tiny" || attr == "gen_init_cpio" then
                      (std.record.get lowered.inputs._rootfs graph.nodes).name == node.name ++ "-build-rootfs"
                    else
                      true
                  ),
              }
          )
          builders
      in
      let kernel_checks =
        std.array.map
          (fun kernel =>
            let node = std.record.get kernel.attr pkgs in
            let previous = std.record.get kernel.attr original in
            let options = std.record.get_or kernel.attr {} (std.record.get_or "options" {} spec) in
            let lines = std.record.get_or kernel.attr [] (std.record.get_or "lines" {} spec) in
            let fragment = std.record.get "config.fragment" node.config.script_config in
            let split_lines = std.string.split "\n" fragment in
            {
              check = "%{kernel.attr}_config",
              correct =
                node.config_options == options
                && (std.array.at 1 node.config.steps).env.BOBR_LINUX_CONFIG_BASE == kernel.base
                && (std.record.get kernel.attr nodes).config == node.config
                && node.config.steps == previous.config.steps
                && std.array.elem kernel.modules split_lines
                && std.array.all (fun line => std.array.elem line split_lines) lines
                && (if std.record.fields options == [] then node.config == previous.config else true),
            }
          )
          kernels
      in
      let expected_modules_tree = std.record.get_or "modules_tree" pkgs.linux spec in
      let expected_image_tree = std.record.get_or "image_tree" pkgs.linux spec in
      let expected_tiny_image_tree = std.record.get_or "tiny_image_tree" pkgs.linux_tiny spec in
      let gen_graph = recipe.to_request { include recipes_path } pkgs pkgs.gen_init_cpio in
      let checks =
        builder_checks
        @ kernel_checks
        @ [
          {
            check = "public_source",
            correct =
              pkgs.linux_src.version == expected_archive.version
              && wire pkgs.linux_src == wire expected_archive
              && nodes.linux_src == wire expected_archive
              && (
                if std.record.has_field "expected_url" spec then
                  pkgs.linux_src.name == "linux-src-9.8.7" && pkgs.linux_src.origin.url == spec.expected_url
                else
                  true
              ),
          },
          {
            check = "modules",
            correct =
              pkgs.linux_modules.name == "linux-modules-%{expected_modules_tree.inputs.source.version}"
              && pkgs.linux_modules.inputs.tree.name == expected_modules_tree.name
              && (std.record.get nodes.linux_modules.inputs.tree graph.nodes).name == expected_modules_tree.name
              && nodes.linux_modules.name == pkgs.linux_modules.name
              && nodes.linux_modules.config == { "include" = ["usr/lib/modules/**"] },
          },
          {
            check = "image",
            correct =
              pkgs.linux_bzimage.name == "linux-bzimage"
              && pkgs.linux_bzimage.inputs.input.name == expected_image_tree.name
              && (std.record.get nodes.linux_bzimage.inputs.input graph.nodes).name == expected_image_tree.name
              && nodes.linux_bzimage.name == "linux-bzimage"
              && nodes.linux_bzimage.config == { copies = [{ from = "boot/bzImage", to = "bzImage" }] },
          },
          {
            check = "tiny_image",
            correct =
              pkgs.linux_tiny_bzimage.name == "linux-bzimage-tiny"
              && pkgs.linux_tiny_bzimage.inputs.input.name == expected_tiny_image_tree.name
              && (std.record.get nodes.linux_tiny_bzimage.inputs.input graph.nodes).name == expected_tiny_image_tree.name
              && nodes.linux_tiny_bzimage.name == "linux-bzimage-tiny"
              && nodes.linux_tiny_bzimage.config == { copies = [{ from = "boot/bzImage", to = "bzImage" }] },
          },
          {
            check = "archiver_has_no_kernel_build_dependency",
            correct =
              std.array.all
                (fun field =>
                  let name = (std.record.get field gen_graph).name in
                  name != pkgs.linux.name && name != pkgs.linux_tiny.name
                )
                (std.record.fields gen_graph),
          },
        ]
      in
      {
        case = spec.label,
        failures = std.array.filter (fun check => !check.correct) checks,
        passed = std.array.all (fun check => check.correct) checks,
      },
}
