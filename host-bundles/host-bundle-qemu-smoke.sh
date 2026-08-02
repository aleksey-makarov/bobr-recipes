#!/usr/bin/env bash

set -euo pipefail

bundle="${1:?usage: host-bundle-qemu-smoke.sh BUNDLE VARIANT GRAPHICAL MEMORY HOME DIAG}"
variant="${2:?missing variant}"
graphical="${3:?missing graphical mode}"
memory="${4:?missing default memory}"
home_image="${5:?missing default home image}"
diag_sock="${6:?missing default diagnostic socket}"
out="${BOBR_OUT_DIR:?BOBR_OUT_DIR is required}"

fail() {
  echo "host-bundle-qemu smoke: $*" >&2
  exit 1
}

for file in \
  root/usr/bin/qemu-system-x86_64 \
  root/usr/bin/qemu-img \
  root/usr/libexec/virgl_render_server \
  root/usr/share/fonts/dejavu/DejaVuSans.ttf \
  root/usr/share/X11/locale/compose.dir \
  root/usr/share/X11/locale/en_US.UTF-8/Compose \
  root/usr/share/qemu/keymaps/en-us \
  overrides/qemu/rootfs.erofs \
  overrides/qemu/bzImage \
  overrides/qemu/initramfs.img; do
  [ -e "${bundle}/${file}" ] || fail "missing ${file}"
done
[ -s "${bundle}/overrides/fontconfig/fonts.conf" ] \
  || fail "missing common bundled fontconfig configuration"

for tool in qemu-system-x86_64 qemu-img bobr-run-qemu; do
  [ -x "${bundle}/bin/${tool}" ] || fail "missing public tool ${tool}"
done
[ -x "${bundle}/libexec/wrapped-bin/virgl_render_server" ] \
  || fail "missing internal virgl render-server wrapper"

"${bundle}/bin/qemu-system-x86_64" --version | grep -Fq 'QEMU emulator version' \
  || fail "qemu-system-x86_64 --version failed"
"${bundle}/bin/qemu-img" --version | grep -Fq 'qemu-img version' \
  || fail "qemu-img --version failed"
accels="$("${bundle}/bin/qemu-system-x86_64" -accel help 2>&1)"
grep -Eq '(^|[[:space:]])kvm($|[[:space:]])' <<<"$accels" \
  || fail "KVM accelerator is absent"
if grep -Eq '(^|[[:space:]])tcg($|[[:space:]])' <<<"$accels"; then
  fail "unexpected TCG accelerator is present"
fi
displays="$("${bundle}/bin/qemu-system-x86_64" -display help 2>&1)"
grep -Eq '(^|[[:space:]])sdl($|[[:space:]])' <<<"$displays" \
  || fail "SDL display backend is absent"
if grep -Eq '(^|[[:space:]])(dbus|gtk)($|[[:space:]])' <<<"$displays"; then
  fail "unexpected D-Bus or GTK display backend is present"
fi
"${bundle}/bin/qemu-system-x86_64" -device virtio-gpu-gl,help 2>&1 | grep -Fq 'venus' \
  || fail "virtio-gpu-gl has no Venus support"
qemu_diagnose="$(env -i "${bundle}/libexec/bobr-bundle-launcher" \
  --diagnose qemu-system-x86_64)"
grep -Fq "argument_prefix=-L ${bundle}/root/usr/share/qemu" <<<"$qemu_diagnose" \
  || fail "QEMU data path argument prefix is absent"
grep -Fq 'environment.RENDER_SERVER_EXEC_PATH=virgl_render_server [tool:replace]' \
  <<<"$qemu_diagnose" \
  || fail "QEMU render-server command override is absent"
grep -Fq "environment.XLOCALEDIR=${bundle}/root/usr/share/X11/locale [tool:replace]" \
  <<<"$qemu_diagnose" \
  || fail "QEMU X locale data path is absent"
grep -Fq "environment.FONTCONFIG_FILE=${bundle}/overrides/fontconfig/fonts.conf [tool:replace]" \
  <<<"$qemu_diagnose" \
  || fail "QEMU fontconfig path is absent"
font_file="$(env -i XDG_CACHE_HOME="${out}/cache" \
  "${bundle}/libexec/bobr-bundle-launcher" \
  --run fc-match -- -f '%{file}\n' sans-serif)"
case "$font_file" in
  "${bundle}/root/usr/share/fonts/"*) ;;
  *) fail "fontconfig resolved outside the bundle: ${font_file}" ;;
esac
render_server_diagnose="$(env -i "${bundle}/libexec/bobr-bundle-launcher" \
  --diagnose virgl_render_server)"
grep -Fq "target=${bundle}/root/usr/libexec/virgl_render_server" \
  <<<"$render_server_diagnose" \
  || fail "internal virgl render-server tool does not resolve to the payload"
runner_diagnose="$(env -i "${bundle}/libexec/bobr-bundle-launcher" \
  --diagnose bobr-run-qemu)"
for setting in \
  "BOBR_QEMU_VARIANT=${variant}" \
  "BOBR_QEMU_GRAPHICAL=${graphical}" \
  "BOBR_QEMU_DEFAULT_MEMORY_MIB=${memory}" \
  "BOBR_QEMU_DEFAULT_HOME_IMAGE=${home_image}" \
  "BOBR_QEMU_DEFAULT_DIAG_SOCK=${diag_sock}"; do
  grep -Fq "environment.${setting} [tool:replace]" <<<"$runner_diagnose" \
    || fail "runner setting is absent: ${setting}"
done

runner_help="$(env -i "${bundle}/bin/bobr-run-qemu" --help)"
grep -Fq "default ./${home_image}" <<<"$runner_help" \
  || fail "runner home image default is absent"
grep -Fq "default ./${diag_sock}" <<<"$runner_help" \
  || fail "runner diagnostic socket default is absent"
grep -Fq "default ${memory}" <<<"$runner_help" \
  || fail "runner memory default is absent"
if [ "$graphical" = 1 ]; then
  grep -Fq 'BOBR_QEMU_DISPLAY' <<<"$runner_help" \
    || fail "graphical runner does not document its display override"
elif grep -Fq 'BOBR_QEMU_DISPLAY' <<<"$runner_help"; then
  fail "headless runner unexpectedly documents a graphical display"
fi

mkdir -p "$out"
cat >"${out}/qemu-smoke.txt" <<'EOF'
status: ok
qemu: KVM-only x86_64-softmmu
display: SDL/Wayland with OpenGL
virtio-gpu: virglrenderer with Venus
boot-artifacts: bundled overrides
EOF
printf 'variant: %s\ngraphical: %s\n' "$variant" "$graphical" \
  >>"${out}/qemu-smoke.txt"
