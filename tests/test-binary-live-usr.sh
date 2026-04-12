#!/usr/bin/env bash
set -euo pipefail

out="${MBUILD_PRIMARY_OUTPUT:?MBUILD_PRIMARY_OUTPUT is required}"
cfg="${MBUILD_SCRIPT_CONFIG_DIR:?MBUILD_SCRIPT_CONFIG_DIR is required}"
name="$(cat "${cfg}/name")"
dest="/out/${out}"
tmp_report="${dest}/report-${name}.tmp"
status="ok"
marker="/usr/bin/mbuild-live-usr-smoke"
output=""

if [ -z "$name" ]; then
  echo "test-binary-live-usr: config name must not be empty" >&2
  exit 1
fi

mkdir -p "$dest"

finish() {
  {
    echo "test-binary-live-usr report"
    echo "name: ${name}"
    echo "marker: ${marker}"
    echo "status: ${status}"
    if [ -n "$output" ]; then
      echo "output: ${output}"
    fi
  } > "${tmp_report}"
  mv "${tmp_report}" "${dest}/report-${name}-${status}.txt"
}

trap 'status="error"; finish' ERR

cat > "${marker}" <<'EOF_INNER'
#!/bin/sh
printf '%s\n' "mbuild live usr smoke ok"
EOF_INNER
chmod 0755 "${marker}"

output="$("${marker}")"
[ "${output}" = "mbuild live usr smoke ok" ]

finish
