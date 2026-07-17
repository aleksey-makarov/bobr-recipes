# Smoke test for the SandboxInstall builder: a build that installs directly
# into the read-write overlay root. The captured artifact must be exactly the
# additive layer (the files below), with no sandbox scaffolding and no
# modifications to the buildpack-deps lower rootfs.
fun pkgs =>
  # Forces the SandboxInstall output tree to be materialized: a `_`-prefixed
  # input is a materialized fs-tree root, so referencing the recipe here turns
  # its manifest into an actual directory tree in the store (fs-trees cache).
  let materialize_sandbox_install_smoke = {
    name = "materialize-sandbox-install-smoke",
    tag = "Group",
    config = {},
    inputs = {
      _tree = pkgs.sandbox_install_smoke,
    },
  }
  in

  let sandbox_install_smoke = {
    name = "sandbox-install-smoke",
    tag = "SandboxInstall",
    config = {
      script_config = {},
      steps = [
        {
          name = "install",
          run_as = "root",
          # Compile in the writable build dir (a bind under /__bobr, stripped
          # from the captured layer); install into the real root so the writes
          # land in the overlay upper layer.
          cwd = "@{build}",
          argv = [
            "/bin/sh",
            "-c",
            m%"
              set -eu
              printf '%s\n' \
                '#include <stdio.h>' \
                'int main(void) { puts("hello from sandbox-install v2"); return 0; }' \
                > hello.c
              cc -O2 -o hello hello.c
              install -D -m 0755 hello /usr/bin/hello
              install -d /usr/share/sandbox-install-smoke
              printf 'smoke test payload\n' > /usr/share/sandbox-install-smoke/message.txt
            "%,
          ],
        },
      ],
    },
    inputs = {
      _rootfs = pkgs.buildpack_deps_rootfs,
    },
  }
  in

  {
    include [
      materialize_sandbox_install_smoke,
      sandbox_install_smoke,
    ],
  }
