#!/usr/bin/env bash
set -euo pipefail

step="${1:-${MBUILD_STEP_NAME:-}}"
step="${step:?step name is required}"
source_dir="${MBUILD_SOURCE_DIR:?MBUILD_SOURCE_DIR is required}"
out_dir="${MBUILD_OUT_DIR:?MBUILD_OUT_DIR is required}"

resolve_source_dir() {
  if [ -f "$source_dir/Configure" ]; then
    printf '%s\n' "$source_dir"
    return
  fi

  local candidates=()
  local d
  for d in "$source_dir"/*; do
    if [ -d "$d" ] && [ -f "$d/Configure" ]; then
      candidates+=("$d")
    fi
  done
  if [ "${#candidates[@]}" -eq 1 ]; then
    printf '%s\n' "${candidates[0]}"
    return
  fi

  echo "perl-configure build-script: Configure not found in ${source_dir}" >&2
  exit 1
}

perl_env() {
  export BUILD_ZLIB=False
  export BUILD_BZIP2=0
}

step_configure() {
  local project_source_dir
  project_source_dir="$(resolve_source_dir)"
  cd "$project_source_dir"
  perl_env
  # perl's Configure probes the build host for values that are not
  # deterministic across machines/days and ignore SOURCE_DATE_EPOCH:
  #   - cf_time: wall-clock time of the Configure run
  #   - osvers / myuname: host kernel release and `uname -a`. The sandbox
  #     shares the host kernel, so `uname -r` is not isolated and leaks the
  #     builder's kernel version.
  #   - cf_by / cf_email / perladmin: the build user. Configure resolves it via
  #     logname/whoami (getpwuid of the build uid), not $USER, so it is not
  #     covered by the sandbox's USER=mbuild. getpwuid(0) resolves differently
  #     between the namespace runtime (-> root) and the host runtime under real
  #     root (-> unknown), so the recorded user leaks the runtime mode.
  # These flow into config.h, Config_heavy.pl, Config.pm, Errno.pm, perlbug
  # and perlthanks. config.over is sourced late (after detection, before
  # config.sh is written), so overriding here only rewrites the recorded
  # values, not any build decision. Use neutral, kernel-independent values
  # (like nixpkgs, which sets osvers=gnulinux / myuname=nixpkgs) rather than a
  # fake version. osvers stays self-consistent: Errno.pm's runtime check
  # compares against the same Config{osvers}.
  {
    printf "cf_time='%s'\n" "$(LC_ALL=C date -u -d "@${SOURCE_DATE_EPOCH:-0}")"
    printf "osvers='gnulinux'\n"
    printf "myuname='mbuild'\n"
    printf "cf_by='mbuild'\n"
    printf "cf_email='mbuild@bobr.nonet'\n"
    printf "perladmin='mbuild@bobr.nonet'\n"
  } > config.over
  sh Configure -des \
    -D prefix=/usr \
    -D vendorprefix=/usr \
    -D privlib=/usr/lib/perl5/5.42/core_perl \
    -D archlib=/usr/lib/perl5/5.42/core_perl \
    -D sitelib=/usr/lib/perl5/5.42/site_perl \
    -D sitearch=/usr/lib/perl5/5.42/site_perl \
    -D vendorlib=/usr/lib/perl5/5.42/vendor_perl \
    -D vendorarch=/usr/lib/perl5/5.42/vendor_perl \
    -D man1dir=/usr/share/man/man1 \
    -D man3dir=/usr/share/man/man3 \
    -D pager='/usr/bin/less -isR' \
    -D useshrplib \
    -D usethreads
}

step_build() {
  local project_source_dir jobs
  project_source_dir="$(resolve_source_dir)"
  cd "$project_source_dir"
  perl_env
  jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
  make -j"$jobs"
}

step_install() {
  local project_source_dir
  project_source_dir="$(resolve_source_dir)"
  cd "$project_source_dir"
  perl_env
  mkdir -p "$out_dir"
  make DESTDIR="$out_dir" install
}

step_post_install() {
  :
}

case "$step" in
  configure) step_configure ;;
  build) step_build ;;
  install) step_install ;;
  post_install) step_post_install ;;
  *)
    echo "perl-configure build-script: unsupported step '$step'" >&2
    exit 1
    ;;
esac
