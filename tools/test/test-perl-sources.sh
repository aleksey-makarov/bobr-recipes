#!/usr/bin/env bash

# Check the aggregated Perl interpreter and CPAN module Sources.
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
let summary = fun packages => {
  perl_src = packages.perl_src,
  parse_yapp_src = packages.perl_parse_yapp_src,
  xml_parser_src = packages.perl_xml_parser_src,
  perl = {
    name = packages.perl.name,
    source = packages.perl.inputs.source,
    step_envs = std.array.map (fun step => step.env) (std.array.slice 1 4 packages.perl.config.steps),
    has_version = std.record.has_field "version" packages.perl,
    has_hash = std.record.has_field "source_object_hash" packages.perl,
  },
  parse_yapp = {
    name = packages.perl_parse_yapp.name,
    source = packages.perl_parse_yapp.inputs.source,
    runtime = std.array.map (fun dep => dep.name) packages.perl_parse_yapp.deps.runtime,
    has_version = std.record.has_field "version" packages.perl_parse_yapp,
    has_hash = std.record.has_field "source_object_hash" packages.perl_parse_yapp,
  },
  xml_parser = {
    name = packages.perl_xml_parser.name,
    source = packages.perl_xml_parser.inputs.source,
    runtime = std.array.map (fun dep => dep.name) packages.perl_xml_parser.deps.runtime,
    has_version = std.record.has_field "version" packages.perl_xml_parser,
    has_hash = std.record.has_field "source_object_hash" packages.perl_xml_parser,
  },
} in
let base_packages = package_set [] in
let replacement_packages = package_set [fun _final => fun _prev => {
  perl = {
    name = "replacement-perl",
    tag = "Source",
    object_hash = "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
  },
}] in
{
  original = summary base_packages,
  versions = summary (package_set [fun _final => fun _prev => {
    perl_src = mk_source "perl-src-5.44.1" "5.44.1" "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    perl_parse_yapp_src = mk_source "perl-parse-yapp-src-1.22" "1.22" "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
    perl_xml_parser_src = mk_source "perl-xml-parser-src-2.48" "2.48" "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
  }]),
  input_replacement = summary (package_set [fun _final => fun prev => {
    perl = prev.perl & {
      inputs.source | force = mk_source "custom-perl-source" "5.46.0" "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
    },
  }]),
  replacement_dependencies = {
    parse_yapp = std.array.map (fun dep => dep.name) replacement_packages.perl_parse_yapp.deps.runtime,
    xml_parser = std.array.map (fun dep => dep.name) replacement_packages.perl_xml_parser.deps.runtime,
  },
}
EOF_NICKEL

jq -e '
  .original.perl_src.name == "perl-src-5.42.2"
  and .original.parse_yapp_src.name == "perl-parse-yapp-src-1.21"
  and .original.xml_parser_src.name == "perl-xml-parser-src-2.47"
  and .original.perl.name == "perl-5.42.2"
  and .original.perl.source == .original.perl_src
  and (.original.perl.step_envs | length) == 3
  and (.original.perl.step_envs | all(.PERL_API_VERSION == "5.42"))
  and (.original.perl.step_envs | all(.BOBR_SOURCE_DIR == "@{build}/source"))
  and (.original.perl.has_version | not)
  and (.original.perl.has_hash | not)
  and .original.parse_yapp.name == "perl-parse-yapp-1.21"
  and .original.parse_yapp.source == .original.parse_yapp_src
  and .original.parse_yapp.runtime == ["perl-5.42.2"]
  and (.original.parse_yapp.has_version | not)
  and (.original.parse_yapp.has_hash | not)
  and .original.xml_parser.name == "perl-xml-parser-2.47"
  and .original.xml_parser.source == .original.xml_parser_src
  and .original.xml_parser.runtime == ["perl-5.42.2", "expat-2.8.2"]
  and (.original.xml_parser.has_version | not)
  and (.original.xml_parser.has_hash | not)
  and .versions.perl.name == "perl-5.44.1"
  and .versions.perl.source.name == "perl-src-5.44.1"
  and (.versions.perl.step_envs | all(.PERL_API_VERSION == "5.44"))
  and .versions.parse_yapp.name == "perl-parse-yapp-1.22"
  and .versions.parse_yapp.source.name == "perl-parse-yapp-src-1.22"
  and .versions.parse_yapp.runtime == ["perl-5.44.1"]
  and .versions.xml_parser.name == "perl-xml-parser-2.48"
  and .versions.xml_parser.source.name == "perl-xml-parser-src-2.48"
  and .versions.xml_parser.runtime == ["perl-5.44.1", "expat-2.8.2"]
  and .input_replacement.perl_src == .original.perl_src
  and .input_replacement.perl.name == "perl-5.46.0"
  and .input_replacement.perl.source.name == "custom-perl-source"
  and (.input_replacement.perl.step_envs | all(.PERL_API_VERSION == "5.46"))
  and .input_replacement.parse_yapp.runtime == ["perl-5.46.0"]
  and .input_replacement.xml_parser.runtime == ["perl-5.46.0", "expat-2.8.2"]
  and .replacement_dependencies.parse_yapp == ["replacement-perl"]
  and .replacement_dependencies.xml_parser == ["replacement-perl", "expat-2.8.2"]
' "${temporary}/result.json" >/dev/null

if rg -F '/usr/lib/perl5/5.42/' "${repo_root}/pkgs/perl/perl-configure.sh" >/dev/null; then
  echo "perl configure script still hard-codes the 5.42 API directory" >&2
  exit 1
fi
test "$(rg -c '\$\{perl_api_version\}' "${repo_root}/pkgs/perl/perl-configure.sh")" -eq 6

echo "Perl Source tests passed (aggregated modules and derived API version)"
