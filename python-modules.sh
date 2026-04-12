#!/usr/bin/env bash
set -euo pipefail

out="${MBUILD_PRIMARY_OUTPUT:-${out:?out is required}}"
cfg="${MBUILD_SCRIPT_CONFIG_DIR:-${cfg:?cfg is required}}"

live_python=/usr/bin/python3
live_pip=(/usr/bin/python3 -m pip)
output_root="/out/${out}"

make install
hash -r

if [ ! -x "${live_python}" ]; then
  echo "python-modules: ${live_python} not found after live install" >&2
  exit 1
fi

export LD_LIBRARY_PATH="/usr/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"

"${live_python}" --version
"${live_python}" -m pip --version

install_python_module() {
  local src_mount="$1"
  local install_name="$2"
  local src_dir="/in/${src_mount}"

  if [ ! -d "${src_dir}" ]; then
    echo "python-modules: source input ${src_mount} is not a directory" >&2
    exit 1
  fi

  echo "python-modules: building ${install_name} from ${src_mount}"
  pushd "${src_dir}" >/dev/null
  rm -rf dist
  "${live_pip[@]}" wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
  "${live_pip[@]}" install --no-index --find-links dist "${install_name}"
  "${live_pip[@]}" install --ignore-installed --no-deps --root "${output_root}" --prefix /usr --no-index --find-links dist "${install_name}"

  if [ "${install_name}" = "meson" ]; then
    install -vDm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson
    install -vDm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson
    install -vDm644 data/shell-completions/bash/meson "${output_root}/usr/share/bash-completion/completions/meson"
    install -vDm644 data/shell-completions/zsh/_meson "${output_root}/usr/share/zsh/site-functions/_meson"
  fi
  popd >/dev/null
}

if [ -d "${cfg}/python_modules" ]; then
  while IFS= read -r -d '' module_dir; do
    source_input="$(cat "${module_dir}/source_input")"
    install_name="$(cat "${module_dir}/install_name")"
    install_python_module "${source_input}" "${install_name}"
  done < <(find "${cfg}/python_modules" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
fi

ninja_source_input="$(cat "${cfg}/ninja_source_input")"
ninja_src_dir="/in/${ninja_source_input}"

if [ ! -d "${ninja_src_dir}" ]; then
  echo "python-modules: ninja source input ${ninja_source_input} is not a directory" >&2
  exit 1
fi

pushd "${ninja_src_dir}" >/dev/null
"${live_python}" configure.py --bootstrap --verbose
install -vm755 ninja /usr/bin/ninja
install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
install -vDm644 misc/zsh-completion /usr/share/zsh/site-functions/_ninja
install -vm755 ninja "${output_root}/usr/bin/ninja"
install -vDm644 misc/bash-completion "${output_root}/usr/share/bash-completion/completions/ninja"
install -vDm644 misc/zsh-completion "${output_root}/usr/share/zsh/site-functions/_ninja"
popd >/dev/null
