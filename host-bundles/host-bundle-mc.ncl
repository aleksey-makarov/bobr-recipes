fun pkgs =>
  let host_bundle_mc_payload = {
    name = "host-bundle-mc-payload",
    tag = "RootfsClosure",
    config = {},
    inputs = {
      mc = pkgs.mc,
      locales = pkgs.glibc_locales,
    },
  }
  in

  let host_bundle_mc = {
    name = "host-bundle-mc",
    tag = "HostBundle",
    config = {
      arch = "x86_64",
      policy = "strict",
      library_dirs = [
        "usr/lib64",
        "usr/lib",
      ],
      public_tools = {
        mc = {
          path = "usr/bin/mc",
          environment = {
            MC_DATADIR = {
              operation = "replace",
              paths = [
                {
                  source = "payload",
                  path = "usr/etc/mc",
                }
              ],
            },
            MC_SHARE_DATADIR = {
              operation = "replace",
              paths = [
                {
                  source = "payload",
                  path = "usr/share/mc",
                }
              ],
            },
            MC_LIBEXECDIR = {
              operation = "replace",
              paths = [
                {
                  source = "payload",
                  path = "usr/libexec/mc",
                }
              ],
            },
          },
        },
      },
      internal_tools = {},
      environment = {
        LOCALE_ARCHIVE = {
          operation = "replace",
          paths = [
            {
              source = "payload",
              path = "usr/lib/locale/locale-archive",
            }
          ],
        },
        TERMINFO = {
          operation = "replace",
          paths = [
            {
              source = "payload",
              path = "usr/share/terminfo",
            }
          ],
        },
        TERMINFO_DIRS = {
          operation = "replace",
          paths = [
            {
              source = "payload",
              path = "usr/share/terminfo",
            }
          ],
        },
      },
    },
    inputs = {
      _root = host_bundle_mc_payload,
      _launcher = pkgs.bobr_bundle_launcher_host_x86_64,
    },
  }
  in

  {
    include [
      host_bundle_mc,
    ],
  }
