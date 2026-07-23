# Image-specific checks for a shipped rootfs, run from OUTSIDE it.
#
# Sourced by check-rootfs.sh (never run on its own): it inherits that script's
# context -- $target (the mounted tree), $cfg (script_config), and the helpers
# add_fail / add_info / config_flag -- and appends to the shared fails/infos.
# All checks are static over the mounted tree; nothing in the image is executed.
# (The old in-image python-import check is intentionally dropped: it required
# running the image's interpreter, and the closure scan already verifies the
# C-extension .so files' NEEDED resolve.)

# --- image filesystem layout ---------------------------------------------------
if ! { [ -L "${target}/sbin" ] && [ "$(readlink "${target}/sbin")" = "usr/bin" ]; }; then
  add_fail "/sbin is not the expected relative symlink to usr/bin"
fi
if ! { [ -L "${target}/usr/sbin" ] && [ "$(readlink "${target}/usr/sbin")" = "bin" ]; }; then
  add_fail "/usr/sbin is not the expected relative symlink to bin"
fi
[ -f "${target}/usr/lib/os-release" ] || add_fail "/usr/lib/os-release is missing"
if ! { [ -L "${target}/etc/os-release" ] \
  && [ "$(readlink "${target}/etc/os-release")" = "../usr/lib/os-release" ]; }; then
  add_fail "/etc/os-release is not the expected relative symlink to ../usr/lib/os-release"
fi
if ! grep -qx 'ID=bobr' "${target}/usr/lib/os-release" 2>/dev/null; then
  add_fail "os-release does not contain ID=bobr"
fi

# --- shebang interpreters (scripts under the executable dirs) -------------------
while IFS= read -r -d '' f; do
  hdr="$(dd if="$f" bs=2 count=1 2>/dev/null || true)"
  [ "$hdr" = "#!" ] || continue
  first="$(sed -n '1{s/^#![[:space:]]*//;p;q}' "$f" 2>/dev/null || true)"
  interp="${first%%[[:space:]]*}"
  [ -n "$interp" ] || continue
  disp="/${f#"${target}/"}"
  case "$interp" in
    /usr/bin/env | /bin/env)
      rest="${first#"$interp"}"
      rest="${rest#"${rest%%[![:space:]]*}"}"
      cmd="${rest%%[[:space:]]*}"
      [ -n "$cmd" ] || continue
      case "$cmd" in
        # `env /abs/path` -- when the argument contains a slash, env execs it
        # directly (no PATH search), so resolve it against the target root like
        # a plain absolute-interpreter shebang. (meson bakes such shebangs, e.g.
        # gobject-introspection's g-ir-scanner: #!/usr/bin/env /usr/sbin/python3.)
        /*)
          [ -e "${target}${cmd}" ] || add_fail "missing env shebang interpreter for ${disp}: ${cmd}"
          ;;
        *)
          if [ ! -e "${target}/usr/bin/${cmd}" ] && [ ! -e "${target}/bin/${cmd}" ]; then
            add_fail "missing env shebang command for ${disp}: ${cmd}"
          fi
          ;;
      esac
      ;;
    /*)
      [ -e "${target}${interp}" ] || add_fail "missing shebang interpreter for ${disp}: ${interp}"
      ;;
  esac
done < <(find "${target}/usr/bin" "${target}/usr/libexec" -type f -print0 2>/dev/null)

# --- graphics stack presence (gated by check_graphics) -------------------------
if config_flag check_graphics; then
  assert_present() {
    local label="$1"
    shift
    local c
    for c in "$@"; do
      [ -e "$c" ] && return 0
    done
    add_fail "missing: ${label}"
  }
  assert_present "kmscube" "${target}/usr/bin/kmscube"
  assert_present "libdrm" "${target}"/usr/lib/libdrm.so*
  assert_present "libgbm" "${target}"/usr/lib/libgbm.so*
  assert_present "libEGL" "${target}"/usr/lib/libEGL.so*
  assert_present "libGLESv2" "${target}"/usr/lib/libGLESv2.so*
  # Modern Mesa ships a single libgallium-<ver>.so; older Mesa per-driver dri.
  assert_present "gallium driver" "${target}"/usr/lib/libgallium-*.so "${target}"/usr/lib/dri/*_dri.so
fi

# --- GNOME GI typelibs (gated by check_gnome) ----------------------------------
# gnome-shell loads GI typelibs by namespace from JS, invisible to the ELF scan,
# so scan the shell libraries' gi:// imports and assert a matching typelib
# exists. Namespaces listed in gnome_optional_typelibs are reported as INFO.
if config_flag check_gnome; then
  optional=""
  [ -f "${cfg}/gnome_optional_typelibs" ] && optional="$(cat "${cfg}/gnome_optional_typelibs")"
  shell_libs=()
  for lib in "${target}"/usr/lib/gnome-shell/*.so; do
    [ -e "$lib" ] && shell_libs+=("$lib")
  done
  if [ "${#shell_libs[@]}" -eq 0 ]; then
    add_fail "no gnome-shell libraries found under /usr/lib/gnome-shell"
  else
    avail="$(find "${target}/usr/lib" -maxdepth 2 -name '*.typelib' 2>/dev/null \
      | sed -E 's#.*/##; s/-[0-9].*//' | sort -u)"
    namespaces="$(strings -- "${shell_libs[@]}" 2>/dev/null \
      | grep -oE 'gi://[A-Za-z][A-Za-z0-9_]*' | sed 's|gi://||' | sort -u || true)"
    for ns in $namespaces; do
      if printf '%s\n' "$avail" | grep -qxF "$ns"; then
        continue
      fi
      case " ${optional} " in
        *" ${ns} "*)
          add_info "optional GI namespace '${ns}' has no typelib (feature not shipped)"
          ;;
        *)
          add_fail "gnome-shell imports GI namespace '${ns}' but no typelib is installed"
          ;;
      esac
    done
  fi
fi
