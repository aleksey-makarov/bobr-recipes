# Shared graphics foundation for the graphical QEMU images (weston, gnome).
#
# Both are Wayland systems on the same accelerated-graphics base but use
# different compositors (weston / mutter), so this is a shared FOUNDATION they
# each extend, not a linear stack. This module is a plain helper (imported
# directly, not part of the pkgs include chain): it exposes the common
# rootfs-closure roots and the finalize step that both images run over their
# merged tree.
let recipe = import "../recipe-lib.ncl" in
{
  # Roots wanted for their own sake in any graphical image: the base rootfs, the
  # accelerated-graphics + Vulkan stack, the kmscube DRM/EGL smoke test, fonts
  # and the cursor theme (pure data, not reachable via link deps), and the xkb
  # keymap data. Their runtime closures pull the rest of the stack automatically.
  graphics_base_roots = fun pkgs => [
    pkgs.qemu_rootfs,
    pkgs.mesa,
    pkgs.vulkan_loader,
    pkgs.vulkan_tools,
    pkgs.kmscube,
    pkgs.dejavu,
    pkgs.bibata_cursors,
    pkgs.xkeyboard_config,
  ],

  # Finalize: regenerate the aggregate caches over the merged tree. These index
  # files are contributed by many packages and cannot be regenerated on the
  # read-only /usr at runtime, so they are baked here at build time (as
  # rpm-ostree/mkosi do). The build runs with the merged tree as a read-write
  # overlay root and captures ONLY the generated caches as an additive layer
  # (SandboxInstall) -- nothing is removed or modified. The generator tools come
  # from the tree itself, so there is no parallel cache env and no version skew.
  # Every step is guarded on the presence of BOTH its input dir AND its generator
  # tool, so a minimal image (weston) that ships e.g. an icon dir pulled in by a
  # dependency but no GTK cache tool simply skips that step (rather than failing
  # with command-not-found).
  # (ld.so.cache is absent from the tree -- glibc no longer ships a partial one.)
  #
  # `label` names the node (`<label>-finalize`); `contents` is the merged
  # RootfsClosure to finalize.
  finalize = fun label =>
    fun contents => {
      name = "%{label}-finalize",
      tag = "SandboxInstall",
      config = {
        script_config = {},
        steps = [
          {
            name = "finalize_caches",
            run_as = "root",
            cwd = "/",
            argv = [
              "/bin/bash",
              "-ec",
              m%"
                # Complete ld.so.cache over the whole tree (glibc ships none now).
                # -X: write only the cache, do not recreate the version symlinks
                # packages already installed.
                ldconfig -X

                # Drop the auxiliary cache. ldconfig always writes it via
                # save_aux_cache() when it builds the cache; -i/--ignore-aux-cache
                # only skips READING an existing one, it does not suppress the
                # write. Its per-library dev/inode/ctime keys are non-reproducible
                # across machines, and it is dead weight on a read-only image
                # (ldconfig never re-runs to use it), so delete it afterwards --
                # as debootstrap/OpenEmbedded do for a reproducible read-only
                # rootfs. The whole dir is created by this build (absent from the
                # base tree), so the removal stays within the additive layer.
                rm -rf /var/cache/ldconfig

                # GSettings schemas -> gschemas.compiled
                if command -v glib-compile-schemas >/dev/null 2>&1 \
                  && [ -d /usr/share/glib-2.0/schemas ]; then
                  glib-compile-schemas /usr/share/glib-2.0/schemas
                fi

                # gdk-pixbuf loaders.cache. Querying the loaders at their runtime
                # path means the SVG loader (librsvg) resolves librsvg-2.so on the
                # normal /usr/lib and the cache records /usr paths directly -- no
                # LD_LIBRARY_PATH and no $out prefix rewriting needed anymore.
                gdkdir=/usr/lib/gdk-pixbuf-2.0/2.10.0
                if command -v gdk-pixbuf-query-loaders >/dev/null 2>&1 \
                  && [ -d "$gdkdir/loaders" ]; then
                  gdk-pixbuf-query-loaders > "$gdkdir/loaders.cache"
                fi

                # GIO modules cache
                if command -v gio-querymodules >/dev/null 2>&1 \
                  && [ -d /usr/lib/gio/modules ]; then
                  gio-querymodules /usr/lib/gio/modules
                fi

                # Icon theme caches
                if command -v gtk4-update-icon-cache >/dev/null 2>&1; then
                  for theme in Adwaita hicolor; do
                    if [ -d "/usr/share/icons/$theme" ]; then
                      gtk4-update-icon-cache -qtf "/usr/share/icons/$theme"
                    fi
                  done
                fi
              "%,
            ],
          },
        ],
      },
      inputs = {
        _rootfs = contents,
      },
    },
}
