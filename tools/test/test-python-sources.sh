#!/usr/bin/env bash

# Check the aggregated CPython and PyPI module Sources and dependencies.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
temporary="$(mktemp -d)"
trap 'rm -rf -- "${temporary}"' EXIT

nickel export --format json >"${temporary}/result.json" <<EOF_NICKEL
let package_set = import "${repo_root}/bobrpkgs.ncl" in
let mk_source = fun name => fun version => fun hash => {
  include name,
  include version,
  tag = "Source",
  object_hash = hash,
  origin = {
    tag = "Http",
    url = "https://example.invalid/%{name}.tar.gz",
  },
} in
let dep_names = fun deps => std.array.map (fun dep => dep.name) deps in
let module_summary = fun module => {
  name = module.name,
  source = module.inputs.source,
  build = dep_names module.deps.build,
  runtime = dep_names module.deps.runtime,
  has_version = std.record.has_field "version" module,
  has_hash = std.record.has_field "source_object_hash" module,
} in
let summary = fun packages => {
  python_src = packages.python_src,
  python_gen1 = {
    name = packages.python_gen1.name,
    source = packages.python_gen1.inputs.source,
    has_version = std.record.has_field "version" packages.python_gen1,
    has_hash = std.record.has_field "source_object_hash" packages.python_gen1,
  },
  python = {
    name = packages.python.name,
    source = packages.python.inputs.source,
    has_version = std.record.has_field "version" packages.python,
    has_hash = std.record.has_field "source_object_hash" packages.python,
  },
  flit_core = module_summary packages.python_flit_core,
  setuptools = module_summary packages.python_setuptools,
  packaging = module_summary packages.python_packaging,
  wheel = module_summary packages.python_wheel,
  six = module_summary packages.python_six,
  markupsafe = module_summary packages.python_markupsafe,
  jinja2 = module_summary packages.python_jinja2,
  mako = module_summary packages.python_mako,
  pyyaml = module_summary packages.python_pyyaml,
} in
let replacement_packages = package_set [fun _final => fun prev => {
  python = prev.python & { name | force = "replacement-python" },
  python_flit_core = prev.python_flit_core & { name | force = "replacement-flit-core" },
  python_setuptools = prev.python_setuptools & { name | force = "replacement-setuptools" },
  python_markupsafe = prev.python_markupsafe & { name | force = "replacement-markupsafe" },
}] in
{
  original = summary (package_set []),
  shared_source = summary (package_set [fun _final => fun _prev => {
    python_src = mk_source "python-src-3.14.1" "3.14.1" "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
  }]),
  final_input = summary (package_set [fun _final => fun prev => {
    python = prev.python & {
      inputs.source | force = mk_source "custom-python-source" "3.15.0" "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
    },
  }]),
  replacement_dependencies = {
    flit_core = module_summary replacement_packages.python_flit_core,
    setuptools = module_summary replacement_packages.python_setuptools,
    packaging = module_summary replacement_packages.python_packaging,
    wheel = module_summary replacement_packages.python_wheel,
    six = module_summary replacement_packages.python_six,
    markupsafe = module_summary replacement_packages.python_markupsafe,
    jinja2 = module_summary replacement_packages.python_jinja2,
    mako = module_summary replacement_packages.python_mako,
    pyyaml = module_summary replacement_packages.python_pyyaml,
  },
}
EOF_NICKEL

jq -e '
  .original.python_src.name == "python-src-3.13.7"
  and .original.python_gen1.name == "python-gen1-3.13.7"
  and .original.python_gen1.source == .original.python_src
  and (.original.python_gen1.has_version | not)
  and (.original.python_gen1.has_hash | not)
  and .original.python.name == "python-3.13.7"
  and .original.python.source == .original.python_src
  and (.original.python.has_version | not)
  and (.original.python.has_hash | not)
  and .original.flit_core.name == "python-flit-core-3.12.0"
  and .original.setuptools.name == "python-setuptools-80.9.0"
  and .original.packaging.name == "python-packaging-25.0"
  and .original.wheel.name == "python-wheel-0.46.1"
  and .original.six.name == "python-six-1.17.0"
  and .original.markupsafe.name == "python-markupsafe-3.0.2"
  and .original.jinja2.name == "python-jinja2-3.1.6"
  and .original.mako.name == "python-mako-1.3.12"
  and .original.pyyaml.name == "python-pyyaml-6.0.3"
  and ([.original.flit_core, .original.setuptools, .original.packaging,
        .original.wheel, .original.six, .original.markupsafe,
        .original.jinja2, .original.mako, .original.pyyaml]
       | all((.has_version | not) and (.has_hash | not)))
  and .shared_source.python_src.name == "python-src-3.14.1"
  and .shared_source.python_gen1.name == "python-gen1-3.14.1"
  and .shared_source.python.name == "python-3.14.1"
  and .shared_source.python_gen1.source == .shared_source.python_src
  and .shared_source.python.source == .shared_source.python_src
  and .final_input.python_src == .original.python_src
  and .final_input.python_gen1.name == "python-gen1-3.13.7"
  and .final_input.python.name == "python-3.15.0"
  and .final_input.python.source.name == "custom-python-source"
  and .final_input.flit_core.runtime == ["python-3.15.0"]
  and .final_input.markupsafe.runtime == ["python-3.15.0"]
  and .replacement_dependencies.packaging.build == ["replacement-flit-core"]
  and .replacement_dependencies.wheel.build == ["replacement-flit-core"]
  and .replacement_dependencies.six.build == ["replacement-setuptools"]
  and .replacement_dependencies.markupsafe.build == ["replacement-setuptools"]
  and .replacement_dependencies.jinja2.build == ["replacement-flit-core"]
  and .replacement_dependencies.jinja2.runtime == ["replacement-python", "replacement-markupsafe"]
  and .replacement_dependencies.mako.build == ["replacement-setuptools"]
  and .replacement_dependencies.mako.runtime == ["replacement-python", "replacement-markupsafe"]
  and .replacement_dependencies.pyyaml.build == ["replacement-setuptools"]
' "${temporary}/result.json" >/dev/null

echo "Python Source tests passed (shared interpreter and aggregated modules)"
