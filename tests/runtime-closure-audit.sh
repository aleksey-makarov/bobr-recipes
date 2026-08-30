#!/usr/bin/env bash
# Aggregate raw per-package runtime-closure reports into a durable audit object.
# Findings never make this script fail: it writes `status` and a complete
# summary, then exits successfully so Bobr imports the audit before the
# dependent gate turns a negative status into a build failure.
set -euo pipefail

inputs="${BOBR_INPUTS_DIR:?BOBR_INPUTS_DIR is required}"
dest="${BOBR_OUT_DIR:?BOBR_OUT_DIR is required}"
reports="${inputs}/reports"
allowlist="${inputs}/allowlist"

if [ ! -d "$reports" ]; then
  echo "runtime-closure-audit: reports input is not a directory" >&2
  exit 1
fi
if [ ! -f "$allowlist" ]; then
  echo "runtime-closure-audit: allowlist input is not a file" >&2
  exit 1
fi

mkdir -p "$dest"
completeness_file="${dest}/completeness-errors.txt"
unexpected_file="${dest}/unexpected-runtime-deps.txt"
approved_file="${dest}/approved-runtime-deps.txt"
redundant_file="${dest}/redundant-runtime-deps.txt"
stale_file="${dest}/stale-allowlist.txt"
policy_file="${dest}/policy-errors.txt"
: > "$completeness_file"
: > "$unexpected_file"
: > "$approved_file"
: > "$redundant_file"
: > "$stale_file"
: > "$policy_file"

declare -A allow_reasons=()
declare -A allow_used=()
while IFS= read -r line || [ -n "$line" ]; do
  [ -n "$line" ] || continue
  [[ "$line" == \#* ]] && continue
  IFS=$'\t' read -r subject dependency reason extra <<< "$line"
  if [ -z "${subject:-}" ] || [ -z "${dependency:-}" ] \
    || [ -z "${reason:-}" ] || [ -n "${extra:-}" ]; then
    printf 'malformed allowlist line: %s\n' "$line" >> "$policy_file"
    continue
  fi
  key="${subject}"$'\t'"${dependency}"
  if [[ -v 'allow_reasons[$key]' ]]; then
    printf 'duplicate allowlist entry: %s -> %s\n' \
      "$subject" "$dependency" >> "$policy_file"
    continue
  fi
  allow_reasons["$key"]="$reason"
  allow_used["$key"]=0
done < "$allowlist"

report_count=0
observed_count=0
declare -A finding_seen=()
while IFS= read -r -d '' report; do
  report_count=$((report_count + 1))
  base="$(basename "$report")"
  if grep -qx 'status: error' "$report"; then
    printf '%s\n' "$base" >> "$completeness_file"
  elif ! grep -qx 'status: ok' "$report"; then
    printf 'report has no valid status: %s\n' "$base" >> "$policy_file"
  fi

  while IFS=$'\t' read -r marker finding subject dependency kind evidence extra; do
    [ "$marker" = "RUNTIME_DEP" ] || continue
    if [ -z "${finding:-}" ] || [ -z "${subject:-}" ] \
      || [ -z "${dependency:-}" ] || [ -z "${kind:-}" ] \
      || [ -z "${evidence:-}" ] || [ -n "${extra:-}" ]; then
      printf 'malformed runtime dependency finding in %s\n' "$base" \
        >> "$policy_file"
      continue
    fi
    finding_key="${finding}"$'\t'"${subject}"$'\t'"${dependency}"
    if [[ -v 'finding_seen[$finding_key]' ]]; then
      printf 'duplicate finding in reports: %s %s -> %s\n' \
        "$finding" "$subject" "$dependency" >> "$policy_file"
      continue
    fi
    finding_seen["$finding_key"]=1

    case "$finding" in
      observed)
        observed_count=$((observed_count + 1))
        ;;
      unobserved)
        key="${subject}"$'\t'"${dependency}"
        if [[ -v 'allow_reasons[$key]' ]]; then
          allow_used["$key"]=1
          printf '%s\t%s\t%s\n' \
            "$subject" "$dependency" "${allow_reasons[$key]}" \
            >> "$approved_file"
        else
          printf '%s\t%s\n' "$subject" "$dependency" \
            >> "$unexpected_file"
        fi
        ;;
      redundant)
        key="${subject}"$'\t'"${dependency}"
        if [[ -v 'allow_reasons[$key]' ]]; then
          allow_used["$key"]=1
          printf '%s\t%s\tredundant via %s; %s\n' \
            "$subject" "$dependency" "$evidence" "${allow_reasons[$key]}" \
            >> "$approved_file"
        else
          printf '%s\t%s\t%s\n' "$subject" "$dependency" "$evidence" \
            >> "$redundant_file"
        fi
        ;;
      *)
        printf 'unknown finding %s in %s\n' "$finding" "$base" \
          >> "$policy_file"
        ;;
    esac
  done < "$report"
done < <(find "$reports" -maxdepth 1 -type f -print0 | sort -z)

for key in "${!allow_reasons[@]}"; do
  if [ "${allow_used[$key]}" -eq 0 ]; then
    subject="${key%%$'\t'*}"
    dependency="${key#*$'\t'}"
    printf '%s\t%s\t%s\n' \
      "$subject" "$dependency" "${allow_reasons[$key]}" >> "$stale_file"
  fi
done

for file in \
  "$completeness_file" \
  "$unexpected_file" \
  "$approved_file" \
  "$redundant_file" \
  "$stale_file" \
  "$policy_file"
do
  LC_ALL=C sort -u "$file" -o "$file"
done

count_lines() {
  local file="$1"
  awk 'END { print NR + 0 }' "$file"
}

completeness_count="$(count_lines "$completeness_file")"
unexpected_count="$(count_lines "$unexpected_file")"
approved_count="$(count_lines "$approved_file")"
redundant_count="$(count_lines "$redundant_file")"
stale_count="$(count_lines "$stale_file")"
policy_count="$(count_lines "$policy_file")"

status=ok
if [ "$completeness_count" -ne 0 ] \
  || [ "$unexpected_count" -ne 0 ] \
  || [ "$redundant_count" -ne 0 ] \
  || [ "$stale_count" -ne 0 ] \
  || [ "$policy_count" -ne 0 ]; then
  status=error
fi
printf '%s\n' "$status" > "${dest}/status"

append_section() {
  local title="$1" file="$2"
  [ -s "$file" ] || return 0
  printf '\n%s:\n' "$title"
  sed 's/^/  /' "$file"
}

{
  echo "runtime closure audit"
  echo "status: ${status}"
  echo "reports: ${report_count}"
  echo "observed runtime dependencies: ${observed_count}"
  echo "approved runtime dependency exceptions: ${approved_count}"
  echo "unexpected unobserved runtime dependencies: ${unexpected_count}"
  echo "redundant runtime dependencies: ${redundant_count}"
  echo "closure errors: ${completeness_count}"
  echo "stale allowlist entries: ${stale_count}"
  echo "policy errors: ${policy_count}"
  append_section "closure errors" "$completeness_file"
  append_section "unexpected unobserved runtime dependencies" "$unexpected_file"
  append_section "redundant runtime dependencies" "$redundant_file"
  append_section "approved runtime dependency exceptions" "$approved_file"
  append_section "stale allowlist entries" "$stale_file"
  append_section "policy errors" "$policy_file"
} > "${dest}/summary.txt"

cat "${dest}/summary.txt" >&2
exit 0
