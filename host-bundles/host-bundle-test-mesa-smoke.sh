#!/usr/bin/env bash
# Reproducible headless smoke test for the host Mesa bundle.
set -euo pipefail

bundle="${1:?usage: host-bundle-test-mesa-smoke.sh BUNDLE}"
root="${bundle}/root"
out="${BOBR_OUT_DIR:?BOBR_OUT_DIR is required}"
work="${BOBR_BUILD_DIR:?BOBR_BUILD_DIR is required}/mesa-smoke"

mkdir -p "$out" "$work"

fail() {
  echo "host-bundle-test-mesa smoke: $*" >&2
  exit 1
}

require_file() {
  [ -f "$1" ] || fail "missing file: ${1#"$bundle"/}"
}

require_executable() {
  [ -x "$1" ] || fail "missing executable: ${1#"$bundle"/}"
}

require_executable "${bundle}/bin/eglinfo-software"
require_executable "${bundle}/bin/vulkaninfo-software"
require_file "${root}/usr/share/glvnd/egl_vendor.d/50_mesa.json"
require_file "${root}/usr/lib/gbm/dri_gbm.so"
require_file "${root}/usr/lib/libdecor/plugins-1/libdecor-cairo.so"
require_file "${root}/usr/lib/libOpenGL.so.0"
require_file "${root}/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf"
require_file "${root}/usr/share/glmark2/models/cat.3ds"
require_file "${bundle}/overrides/fontconfig/fonts.conf"
grep -aFq "libOpenGL.so.0" "${root}/usr/bin/glmark2-wayland" ||
  fail "desktop glmark2 does not use the X11-free GLVND OpenGL frontend"

font_cache="${work}/font-cache"
mkdir -p "$font_cache"
for family in sans-serif sans; do
  font_path="$(
    XDG_CACHE_HOME="$font_cache" \
      "${bundle}/libexec/wrapped-bin/fc-match" \
      --format '%{file}\n' ":family=${family}"
  )"
  case "$font_path" in
    "${root}"/usr/share/fonts/dejavu/DejaVuSans.ttf) ;;
    *)
      fail \
        "fontconfig did not select bundled DejaVu Sans for ${family}: ${font_path:-<empty>}"
      ;;
  esac
done

shopt -s nullglob
gallium=("${root}"/usr/lib/libgallium-*.so)
[ "${#gallium[@]}" -eq 1 ] ||
  fail "expected exactly one unified libgallium, found ${#gallium[@]}"

icd_dir="${root}/usr/share/vulkan/icd.d"
expected_icds=(
  intel_icd.x86_64.json
  intel_hasvk_icd.x86_64.json
  lvp_icd.x86_64.json
  nouveau_icd.x86_64.json
  radeon_icd.x86_64.json
)

json_library_path() {
  sed -n \
    's/^[[:space:]]*"library_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    "$1"
}

check_manifest() {
  local manifest="$1" library
  library="$(json_library_path "$manifest")"
  [ -n "$library" ] ||
    fail "library_path is absent in ${manifest#"$bundle"/}"
  case "$library" in
    /*|*/*)
      fail "library_path is not a bare bundled soname in ${manifest#"$bundle"/}: ${library}"
      ;;
  esac
  require_file "${root}/usr/lib/${library}"
}

for manifest_name in "${expected_icds[@]}"; do
  manifest="${icd_dir}/${manifest_name}"
  require_file "$manifest"
  check_manifest "$manifest"
done

egl_manifest="${root}/usr/share/glvnd/egl_vendor.d/50_mesa.json"
egl_library="$(json_library_path "$egl_manifest")"
[ "$egl_library" = "libEGL_mesa.so.0" ] ||
  fail "unexpected EGL vendor library_path: ${egl_library:-<empty>}"
require_file "${root}/usr/lib/${egl_library}"

# Check every ELF in the payload statically. The bundle deliberately has only
# these two library directories, matching bundle.toml. Scanning libraries as
# well as executables makes the DT_NEEDED check transitive.
is_elf() {
  [ "$(dd if="$1" bs=4 count=1 2>/dev/null |
    od -An -tx1 -v 2>/dev/null | tr -d ' \n')" = "7f454c46" ]
}

resolve_needed() {
  local name="$1"
  [ -e "${root}/usr/lib/${name}" ] ||
    [ -e "${root}/usr/lib64/${name}" ]
}

while IFS= read -r -d '' elf; do
  is_elf "$elf" || continue

  while IFS= read -r needed; do
    [ -n "$needed" ] || continue
    resolve_needed "$needed" ||
      fail "unresolved DT_NEEDED ${needed} from ${elf#"$bundle"/}"
  done < <(
    readelf -d "$elf" 2>/dev/null |
      sed -n 's/.*(NEEDED).*Shared library: \[\([^]]*\)\].*/\1/p'
  )

  while IFS= read -r search_path; do
    [ -n "$search_path" ] || continue
    IFS=: read -r -a entries <<<"$search_path"
    for entry in "${entries[@]}"; do
      case "$entry" in
        /*)
          fail "absolute ELF search path ${entry} in ${elf#"$bundle"/}"
          ;;
      esac
    done
  done < <(
    readelf -d "$elf" 2>/dev/null |
      sed -n 's/.*(\(RPATH\|RUNPATH\)).*Library \(rpath\|runpath\): \[\([^]]*\)\].*/\3/p'
  )
done < <(find "$root" -type f -print0)

egl_log="${work}/eglinfo.txt"
"${bundle}/bin/eglinfo-software" -B -p surfaceless >"$egl_log" 2>&1
grep -Fq "EGL vendor string: Mesa Project" "$egl_log" ||
  fail "eglinfo did not select bundled Mesa"
grep -Eiq 'OpenGL .*renderer:.*llvmpipe' "$egl_log" ||
  fail "eglinfo did not select llvmpipe"
grep -Eq 'OpenGL core profile version:.*Mesa' "$egl_log" ||
  fail "desktop OpenGL core profile is absent"
grep -Eq 'OpenGL ES profile version:.*Mesa' "$egl_log" ||
  fail "OpenGL ES profile is absent"

vk_log="${work}/vulkaninfo.txt"
"${bundle}/bin/vulkaninfo-software" --summary >"$vk_log" 2>&1
grep -Fq "DRIVER_ID_MESA_LLVMPIPE" "$vk_log" ||
  fail "vulkaninfo did not select Lavapipe"
grep -Eq 'driverName[[:space:]]*= llvmpipe' "$vk_log" ||
  fail "unexpected Vulkan driver"
grep -Eq 'deviceType[[:space:]]*= PHYSICAL_DEVICE_TYPE_CPU' "$vk_log" ||
  fail "Lavapipe was not reported as a CPU device"
[ "$(grep -Ec '^GPU[0-9]+:' "$vk_log")" -eq 1 ] ||
  fail "software Vulkan wrapper exposed an unexpected number of devices"

cat >"${out}/software-smoke.txt" <<'EOF'
status: ok
egl: Mesa llvmpipe
vulkan: Mesa Lavapipe
manifests: relative bundled sonames
elf-closure: complete inside bundle
EOF
