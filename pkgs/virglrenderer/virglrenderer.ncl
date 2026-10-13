fun pkgs =>
  let virglrenderer_src = {
    version | default = "1.3.0",
    name = "virglrenderer-src-%{version}",
    tag = "Source",
    object_hash | default = "065bc56e89e6f631f96101cd62eba0748e48eb888b434edc86e89d05395e76f3",
    origin = {
      tag = "Http",
      url = "https://gitlab.freedesktop.org/virgl/virglrenderer/-/archive/%{version}/virglrenderer-%{version}.tar.gz",
    },
  }
  in

  let render_server_path_patch = {
    name = "virglrenderer-render-server-path-patch",
    tag = "Source",
    object_hash =
      import "virglrenderer-render-server-path.patch.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "pkgs/virglrenderer/virglrenderer-render-server-path.patch",
    },
  }
  in

  let virglrenderer = {
    name = "virglrenderer-%{inputs.source.version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.pkgconf,
        pkgs.python_pyyaml,
        pkgs.libepoxy_host,
        pkgs.libdrm,
        pkgs.mesa,
        pkgs.vulkan_headers,
        pkgs.vulkan_loader,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.libepoxy_host,
        pkgs.libdrm_libs,
        pkgs.mesa,
        pkgs.vulkan_loader,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dtests=false",
        "-Dvideo=false",
        "-Dvenus=true",
        "-Dvulkan-dload=false",
        "-Ddrm-renderers=",
      ],
      post_install = {
        name = "check_install",
        run_as = "root",
        argv = [
          "/bin/sh",
          "-ec",
          "test -s /usr/lib/libvirglrenderer.so.1 && test -s /usr/lib/pkgconfig/virglrenderer.pc",
        ],
      },
    },
    inputs = {
      source = pkgs.virglrenderer_src,
      patch_render_server_path = render_server_path_patch,
    },
  }
  in

  {
    include [
      virglrenderer_src,
      virglrenderer,
    ],
  }
