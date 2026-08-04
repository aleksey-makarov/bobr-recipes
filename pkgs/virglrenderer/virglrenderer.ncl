fun pkgs =>
  let virglrenderer_src = fun version => fun hash => {
    name = "virglrenderer-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url =
        "https://gitlab.freedesktop.org/virgl/virglrenderer/-/archive/%{version}/virglrenderer-%{version}.tar.gz",
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
    version | default = "1.3.0",
    source_object_hash | default = "065bc56e89e6f631f96101cd62eba0748e48eb888b434edc86e89d05395e76f3",
    name = "virglrenderer-%{version}",
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
        pkgs.glibc_libs,
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
      source = virglrenderer_src version source_object_hash,
      patch_render_server_path = render_server_path_patch,
    },
  }
  in

  {
    include [
      render_server_path_patch,
      virglrenderer,
    ],
  }
