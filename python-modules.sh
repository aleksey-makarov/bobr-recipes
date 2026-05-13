#!/usr/bin/env bash
set -euo pipefail

cfg="${MBUILD_CONFIG_DIR:?MBUILD_CONFIG_DIR is required}"
out_dir="${MBUILD_OUT_DIR:?MBUILD_OUT_DIR is required}"
work_dir="${MBUILD_BUILD_DIR:-$PWD}"

live_python="${out_dir}/usr/bin/python3"
if [ ! -x "${live_python}" ]; then
  live_python="${out_dir}/usr/bin/python3.13"
fi
live_pip=("${live_python}" -m pip)
output_root="$out_dir"
wheels_root="${work_dir}/python-wheels"

install_python_module() {
  local package_name="$1"
  local src_dir="/__mbuild/inputs/${package_name}"
  local wheel_dir="${wheels_root}/${package_name}"

  if [ ! -d "${src_dir}" ]; then
    echo "python-modules: source input ${package_name} is not a directory" >&2
    exit 1
  fi

  echo "python-modules: building ${package_name}"
  rm -rf "${wheel_dir}"
  mkdir -p "${wheel_dir}"
  "${live_pip[@]}" wheel -w "${wheel_dir}" --no-cache-dir --no-build-isolation --no-deps "${src_dir}"
  "${live_pip[@]}" install --ignore-installed --no-deps --root "${output_root}" --prefix /usr --no-index --find-links "${wheel_dir}" "${package_name}"

  if [ "${package_name}" = "meson" ]; then
    install -vDm644 "${src_dir}/data/shell-completions/bash/meson" "${output_root}/usr/share/bash-completion/completions/meson"
    install -vDm644 "${src_dir}/data/shell-completions/zsh/_meson" "${output_root}/usr/share/zsh/site-functions/_meson"
  fi
}

export PATH="${out_dir}/usr/bin:${PATH}"
export PYTHONHOME="${out_dir}/usr"
export LD_LIBRARY_PATH="${out_dir}/usr/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
hash -r

if [ ! -x "${live_python}" ]; then
  echo "python-modules: staged Python not found in ${out_dir}/usr/bin" >&2
  exit 1
fi

"${live_python}" --version
"${live_python}" -m pip --version

if [ -d "${cfg}/python_modules" ]; then
  while IFS= read -r -d '' module_file; do
    install_python_module "$(cat "${module_file}")"
  done < <(find "${cfg}/python_modules" -mindepth 1 -maxdepth 1 -type f -print0 | sort -z)
fi

ninja_src_dir="/__mbuild/inputs/ninja"

if [ ! -d "${ninja_src_dir}" ]; then
  echo "python-modules: ninja source input is not a directory" >&2
  exit 1
fi

pushd "${ninja_src_dir}" >/dev/null
"${live_python}" configure.py --bootstrap --verbose
install -vm755 ninja "${output_root}/usr/bin/ninja"
install -vDm644 misc/bash-completion "${output_root}/usr/share/bash-completion/completions/ninja"
install -vDm644 misc/zsh-completion "${output_root}/usr/share/zsh/site-functions/_ninja"
popd >/dev/null
