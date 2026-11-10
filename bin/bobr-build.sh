#!/usr/bin/env bash
# `resolve_profile` in the sourced profile library assigns the profile_* names.
# shellcheck disable=SC2154

# Builds one recipe from these recipes, as described by a build profile.
#
# Usage:
#   bobr-build.sh [OPTIONS] [PROFILE.ncl]
#
#   PROFILE.ncl              the build profile (default: ./bobr.ncl); normally
#                            imports <recipes>/profiles/bobr-user.ncl
#   --target NAME            build this recipe instead of the profile's goals;
#                            repeat to select several ordered goals
#   --jobs N | -j N          cap builders running at once
#   --quiet                  keep only warnings and errors on screen
#   --dry-run                print the resolved profile and the JSON request,
#                            build nothing
#   -h | --help              show this help
#
# The profile says where to build and what; this run's name and its log and work
# directories are minted here, per invocation. Bobr host tools come from PATH.

set -euo pipefail

usage() {
  sed -n '3,18p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2
}

script_path="$(readlink -f "${BASH_SOURCE[0]}")"
recipes_path="$(cd "$(dirname "${script_path}")/.." && pwd)"
tool="bobr-build.sh"
# shellcheck source=profiles/profile-lib.sh
. "${recipes_path}/profiles/profile-lib.sh"
# shellcheck source=profiles/publish-lib.sh
. "${recipes_path}/profiles/publish-lib.sh"

profile_path=""
targets=()
jobs=""
quiet=""
dry_run=0

recipes_provenance() {
  local commit dirty status
  if ! command -v git >/dev/null 2>&1 \
    || ! git -C "${recipes_path}" rev-parse --is-inside-work-tree \
      >/dev/null 2>&1; then
    printf '%s\n' null
    return
  fi
  commit="$(git -C "${recipes_path}" rev-parse HEAD 2>/dev/null)" \
    || { printf '%s\n' null; return; }
  status="$(git -C "${recipes_path}" status --porcelain \
    --untracked-files=normal 2>/dev/null)" \
    || { printf '%s\n' null; return; }
  dirty=false
  if [ -n "${status}" ]; then
    dirty=true
  fi
  printf '{"git_commit":"%s","git_dirty":%s}\n' "${commit}" "${dirty}"
}

write_run_context() {
  local outcome="$1" exit_status="$2" temporary_context
  temporary_context="$(mktemp "${logs_path}/.context.json.XXXXXX")"
  {
    printf '{"schema":"bobr-run-context-v2"'
    printf ',"run_id":"%s","goals":%s' "${run_id}" "${run_goals_json}"
    printf ',"outcome":"%s","exit_status":%s' "${outcome}" "${exit_status}"
    printf ',"bobr":%s,"recipes":%s}\n' \
      "${tool_build_info}" "${run_recipes_provenance}"
  } > "${temporary_context}"
  mv -f "${temporary_context}" "${logs_path}/context.json"
}

write_recipe_catalog() {
  local request_path="$1" temporary_catalog
  temporary_catalog="$(mktemp "${logs_path}/.recipe-catalog.json.XXXXXX")"
  if ! nickel export --format json > "${temporary_catalog}" <<EOF_CATALOG
let request = import "${request_path}" as 'Json in
{
  schema = "bobr-recipe-catalog-v1",
  nodes = std.record.map
    (fun _name node => { name = node.name, tag = node.tag })
    request.nodes,
}
EOF_CATALOG
  then
    rm -f "${temporary_catalog}"
    return 1
  fi
  mv -f "${temporary_catalog}" "${logs_path}/recipe-catalog.json"
}

cleanup_podman_state() {
  [ -n "${podman_state_dir:-}" ] || return 0
  rm -f "${podman_state_dir}/pid.fifo" "${podman_state_dir}/pid"
  rmdir "${podman_state_dir}" 2>/dev/null || true
  podman_state_dir=""
}

run_bobr_direct() {
  local request_path="$1"
  local bobr_pid="" pending_signal="" wait_status=0

  forward_bobr_signal() {
    pending_signal="$1"
    if [ -n "${bobr_pid}" ]; then
      kill -s "$1" -- "${bobr_pid}" 2>/dev/null || true
    fi
  }

  trap 'forward_bobr_signal INT' INT
  trap 'forward_bobr_signal TERM' TERM

  (
    trap - INT TERM
    exec bobr < "${request_path}"
  ) &
  bobr_pid="$!"
  if [ -n "${pending_signal}" ]; then
    kill -s "${pending_signal}" -- "${bobr_pid}" 2>/dev/null || true
  fi

  while :; do
    wait_status=0
    wait "${bobr_pid}" || wait_status="$?"
    if ! kill -0 "${bobr_pid}" 2>/dev/null; then
      break
    fi
  done

  trap - INT TERM
  return "${wait_status}"
}

run_bobr_under_podman() {
  local request_path="$1"
  local pid_fifo pid_file reader_pid podman_pid
  local bobr_pid="" pending_signal=""
  local completed="" wait_status=0 podman_status=0
  local reader_reaped=0 podman_reaped=0

  forward_bobr_signal() {
    pending_signal="$1"
    if [ -n "${bobr_pid}" ]; then
      kill -s "$1" -- "${bobr_pid}" 2>/dev/null || true
    fi
  }

  trap 'forward_bobr_signal INT' INT
  trap 'forward_bobr_signal TERM' TERM

  podman_state_dir="$(mktemp -d)"
  pid_fifo="${podman_state_dir}/pid.fifo"
  pid_file="${podman_state_dir}/pid"
  mkfifo -m 600 "${pid_fifo}"

  # The reader turns the FIFO handshake into a waitable process. This lets us
  # detect Podman startup failure without polling for either a PID file or a
  # process-tree shape.
  (
    trap '' INT
    IFS= read -r child_pid < "${pid_fifo}"
    printf '%s\n' "${child_pid}" > "${pid_file}"
  ) &
  reader_pid="$!"

  # Keep the driver in the terminal's foreground process group. Podman and
  # Bobr run in a separate session, so Ctrl-C reaches this script first. The
  # inner shell reports the PID which exec will preserve for Bobr.
  # shellcheck disable=SC2016
  setsid --wait podman unshare sh -c '
    pid_fifo=$1
    shift
    printf "%s\n" "$$" > "${pid_fifo}"
    exec "$@"
  ' sh "${pid_fifo}" bobr < "${request_path}" &
  podman_pid="$!"

  while [ ! -s "${pid_file}" ]; do
    completed=""
    wait_status=0
    wait -n -p completed "${reader_pid}" "${podman_pid}" \
      || wait_status="$?"
    if [ -z "${completed:-}" ]; then
      # A trapped terminal signal interrupted wait. Forwarding is deferred
      # until the Bobr PID arrives through the handshake.
      continue
    fi
    if [ "${completed}" = "${reader_pid}" ]; then
      reader_reaped=1
      break
    fi
    podman_reaped=1
    podman_status="${wait_status}"
    if [ -s "${pid_file}" ]; then
      break
    fi
    kill "${reader_pid}" 2>/dev/null || true
    wait "${reader_pid}" 2>/dev/null || true
    trap - INT TERM
    cleanup_podman_state
    return "${podman_status}"
  done

  IFS= read -r bobr_pid < "${pid_file}"
  if ! [[ "${bobr_pid}" =~ ^[1-9][0-9]*$ ]]; then
    echo "${tool}: podman unshare reported an invalid Bobr PID" >&2
    kill -TERM -- "-${podman_pid}" 2>/dev/null || true
    wait "${podman_pid}" 2>/dev/null || true
    trap - INT TERM
    cleanup_podman_state
    return 2
  fi
  if [ -n "${pending_signal}" ]; then
    kill -s "${pending_signal}" -- "${bobr_pid}" 2>/dev/null || true
  fi

  if [ "${reader_reaped}" -eq 0 ]; then
    wait "${reader_pid}" 2>/dev/null || true
  fi
  if [ "${podman_reaped}" -eq 0 ]; then
    while :; do
      completed=""
      wait_status=0
      wait -n -p completed "${podman_pid}" || wait_status="$?"
      if [ -n "${completed:-}" ]; then
        podman_status="${wait_status}"
        break
      fi
    done
  fi

  trap - INT TERM
  cleanup_podman_state
  return "${podman_status}"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target)
      [ "$#" -ge 2 ] || die "$1 requires a value"
      [[ "$2" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] \
        || die "invalid recipe attribute name: $2"
      targets+=("$2")
      shift 2
      ;;
    --jobs | -j)
      [ "$#" -ge 2 ] || die "$1 requires a value"
      jobs="$2"
      shift 2
      ;;
    --quiet)
      quiet=1
      shift
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    --*)
      die "unknown option: $1"
      ;;
    *)
      [ -z "${profile_path}" ] || die "unexpected argument: $1"
      profile_path="$1"
      shift
      ;;
  esac
done

[ -n "${profile_path}" ] || profile_path="bobr.ncl"
profile_given="${profile_path}"
profile_path="$(realpath -e -- "${profile_given}" 2>/dev/null)" \
  || die "no build profile at '${profile_given}'; create ./bobr.ncl with ${recipes_path}/bobrpkgs.ncl, explicit goals, and the bobr-user.ncl preset"

if [ -n "${jobs}" ] && ! [[ "${jobs}" =~ ^[1-9][0-9]*$ ]]; then
  die "--jobs must be a positive integer"
fi
require_cmd nickel
require_cmd bobr

resolve_profile "${profile_path}"

store_path="${profile_store}"
logs_root="${profile_logs}"
work_root="${profile_work}"
limits_expr="${profile_fetch}"
secondaries_expr="${profile_secondaries}"
progress_expr="${profile_progress}"
[ -n "${jobs}" ] || { [ "${profile_jobs}" = "0" ] || jobs="${profile_jobs}"; }
[ -n "${quiet}" ] || quiet="${profile_quiet}"
podman_unshare="${profile_podman_unshare}"

[ -d "${store_path}" ] \
  || die "store does not exist: ${store_path} (create it: mkdir -p '${store_path}')"

check_request_schema "${recipes_path}/request-schema.ncl" bobr

# Local Source paths are content-addressed by adjacent lock files. Check the
# whole recipes tree before relying on cached Source objects: a warm store must
# not hide a local edit whose lock was not refreshed.
"${recipes_path}/bin/bobr-update-fsobj-hashes.sh" --check \
  || die "recipe hash locks are stale; refresh them: ${recipes_path}/bin/bobr-update-fsobj-hashes.sh"

if [ "${dry_run}" -eq 1 ]; then
  # A dry run creates nothing: it names the directories a real build would have
  # made and stops after lowering.
  run_id="$(date '+%y%m%d%H%M%S')"
else
  mkdir -p "${logs_root}" "${work_root}"
  run_id="$(allocate_run_id "${logs_root}" "${work_root}")"
fi
logs_path="${logs_root}/${run_id}"
work_path="${work_root}/${run_id}"

merge_fields=()
[ -n "${jobs}" ] && merge_fields+=("jobs = ${jobs}")
[ "${quiet}" -eq 1 ] && merge_fields+=("quiet = true")
merge_expr=""
if [ "${#merge_fields[@]}" -gt 0 ]; then
  merge_expr=" & { $(IFS=,; echo "${merge_fields[*]}") }"
fi

goals_expr="profile.goals"
display_goals="${profile_goals_json}"
if [ "${#targets[@]}" -gt 0 ]; then
  goal_items=()
  for target in "${targets[@]}"; do
    goal_items+=("(if std.record.has_field \"${target}\" profile.pkgs then
      std.record.get \"${target}\" profile.pkgs
    else
      std.fail_with \"bobr-build.sh: no recipe attribute named '${target}'; list available attributes with bin/bobr-list-pkgs.sh\")")
  done
  goals_expr="[$(IFS=,; echo "${goal_items[*]}")]"
  display_goals="[$(printf '"%s",' "${targets[@]}" | sed 's/,$//')]"
fi

request_expr="let contracts = import \"${recipes_path}/profiles/contracts.ncl\" in
let profile | contracts.Profile = import \"${profile_path}\" in
(import \"${recipes_path}/request.ncl\") {
  store_path = \"${store_path}\",
  logs_path = \"${logs_path}\",
  work_path = \"${work_path}\",
  run_id = \"${run_id}\",
  recipes_path = \"${recipes_path}\",
  pkgs = profile.pkgs,
  goals = ${goals_expr},
  progress = ${progress_expr},
  limits = ${limits_expr},
  secondaries = ${secondaries_expr},
}${merge_expr}"


if [ "${dry_run}" -eq 1 ]; then
  {
    echo "==> profile ${profile_path} resolves to:"
    printf '%s\n' "${profile_resolved}" | sed 's/^profile_/  /'
    echo "==> goals: ${display_goals}"
    echo "==> ${tool_version}"
  } >&2
  echo "==> evaluate Nickel recipes and generate JSON request" >&2
  nickel_started_at="$(date +%s.%N)"
  printf '%s\n' "${request_expr}" | nickel export --format json
  nickel_finished_at="$(date +%s.%N)"
  report_phase_time "nickel recipes -> json request" \
    "${nickel_started_at}" "${nickel_finished_at}"
  exit 0
fi

podman_state_dir=""
if [ "${podman_unshare}" -eq 1 ]; then
  require_cmd podman
  require_cmd setsid
  require_cmd mkfifo
fi

# Export the request to a file first -- timed on its own -- rather than piping
# nickel straight into bobr, so the recipes -> JSON pass and the build itself are
# measured and reported separately.
request_json="$(mktemp)"
trap 'rm -f "${request_json}"; cleanup_podman_state' EXIT
echo "==> evaluate Nickel recipes and generate JSON request" >&2
nickel_started_at="$(date +%s.%N)"
printf '%s\n' "${request_expr}" | nickel export --format json > "${request_json}"
nickel_finished_at="$(date +%s.%N)"
report_phase_time "nickel recipes -> json request" \
  "${nickel_started_at}" "${nickel_finished_at}"

run_goals_json="$(nickel export --format raw <<EOF_GOALS
let request = import "${request_json}" as 'Json in
let names = std.array.map
  (fun id => (std.record.get id request.nodes).name)
  request.goals
in
"[" ++ std.string.join "," (std.array.map (std.serialize 'Json) names) ++ "]"
EOF_GOALS
)" || die "failed to read lowered goals from the generated request"

run_recipes_provenance="$(recipes_provenance)"
write_recipe_catalog "${request_json}"
write_run_context running null

bobr_started_at="$(date +%s.%N)"
bobr_status=0
if [ "${podman_unshare}" -eq 1 ]; then
  run_bobr_under_podman "${request_json}" || bobr_status="$?"
else
  run_bobr_direct "${request_json}" || bobr_status="$?"
fi
bobr_finished_at="$(date +%s.%N)"
report_phase_time "bobr build" "${bobr_started_at}" "${bobr_finished_at}"
if [ "${bobr_status}" -ne 0 ]; then
  write_run_context failed "${bobr_status}"
  exit "${bobr_status}"
fi

write_run_context success 0

run_output_repository_stage
