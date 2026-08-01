#!/usr/bin/env bash

set -euo pipefail

bundle="${1:?usage: host-bundle-qemu-smoke.sh BUNDLE}"
out="${BOBR_OUT_DIR:?BOBR_OUT_DIR is required}"

fail() {
  echo "host-bundle-qemu smoke: $*" >&2
  exit 1
}

for file in \
  root/usr/bin/qemu-system-x86_64 \
  root/usr/bin/qemu-img \
  root/usr/share/qemu/keymaps/en-us \
  overrides/qemu/rootfs.erofs \
  overrides/qemu/bzImage \
  overrides/qemu/initramfs.img; do
  [ -e "${bundle}/${file}" ] || fail "missing ${file}"
done

for tool in qemu-system-x86_64 qemu-img bobr-run-qemu; do
  [ -x "${bundle}/bin/${tool}" ] || fail "missing public tool ${tool}"
done

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
"${bundle}/bin/bobr-run-qemu" --help | grep -Fq -- '--home-image' \
  || fail "runner help failed"
"${bundle}/libexec/bobr-bundle-launcher" --diagnose qemu-system-x86_64 \
  | grep -Fq "argument_prefix=-L ${bundle}/root/usr/share/qemu" \
  || fail "QEMU data path argument prefix is absent"

mkdir -p "$out"
cat >"${out}/qemu-smoke.txt" <<'EOF'
status: ok
qemu: KVM-only x86_64-softmmu
display: SDL/Wayland with OpenGL
virtio-gpu: virglrenderer with Venus
boot-artifacts: bundled overrides
EOF
