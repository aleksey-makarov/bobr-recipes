#!/usr/bin/env bash
set -euo pipefail

phase="${1:-${MBUILD_STEP_NAME:-}}"
phase="${phase:?step name is required}"
source_dir="${MBUILD_SOURCE_DIR:?MBUILD_SOURCE_DIR is required}"
install_dir="${MBUILD_INSTALL_DIR:?MBUILD_INSTALL_DIR is required}"

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

phase_configure() {
  local project_source_dir
  project_source_dir="$(resolve_source_dir)"
  cd "$project_source_dir"
  perl_env
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

phase_build() {
  local project_source_dir jobs
  project_source_dir="$(resolve_source_dir)"
  cd "$project_source_dir"
  perl_env
  jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
  make -j"$jobs"
}

phase_install() {
  local project_source_dir
  project_source_dir="$(resolve_source_dir)"
  cd "$project_source_dir"
  perl_env
  mkdir -p "$install_dir"
  make DESTDIR="$install_dir" install
}

phase_post_install() {
  :
}

case "$phase" in
  configure) phase_configure ;;
  build) phase_build ;;
  install) phase_install ;;
  post_install) phase_post_install ;;
  *)
    echo "perl-configure build-script: unsupported phase '$phase'" >&2
    exit 1
    ;;
esac
