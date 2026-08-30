# Prebuilt LLVM/Clang toolchain used by packages that need LLVM development
# libraries, libclang, or selected LLVM command-line tools. It is primarily a
# build package, but tools such as bindgen include it in their runtime closure
# because they load libclang dynamically.
#
# `version`/`source_object_hash` are node fields (overridable), as in linux.ncl.
let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let mk_src = fun version =>
    fun hash =>
      {
        name = "llvm-bin-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://github.com/llvm/llvm-project/releases/download/llvmorg-%{version}/LLVM-%{version}-Linux-X64.tar.xz",
        },
      }
  in

  # The upstream archive is around 12 GiB unpacked because most command-line
  # tools link LLVM
  # statically. Keep a coherent development subset instead of copying every
  # standalone tool. LLVM itself is linked statically into consumers, so this
  # package remains a build dependency and does not enter runtime closures.
  let llvm_bin = {
    version | default = "22.1.8",
    source_object_hash
      | default
      = "df0e1ecf16caf3489a272a5eea4eec9b0d82878f6477fa309504f918a0006384",
    name = "llvm-bin-%{version}",
    tag = "SandboxInstallDeps",
    deps = {
      build = [
        pkgs.coreutils,
        pkgs.findutils,
        pkgs.grep,
        pkgs.sed,
        pkgs.tar,
        # The install step executes the imported tools for validation.
        pkgs.gcc_libstdcxx,
        pkgs.zlib,
        pkgs.zstd,
        pkgs.zstd_static,
        pkgs.libxml2,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.gcc_libstdcxx,
        pkgs.zlib,
        pkgs.zstd,
        pkgs.zstd_static,
        pkgs.libxml2,
      ],
    },
    config = {
      steps = [
        recipe.prepare_source_step,
        {
          name = "install",
          run_as = "root",
          cwd = "@{build}",
          argv = [
            "/bin/bash",
            "-ec",
            m%"
              source_dir="@{build}/source"

              install -d \
                /usr/bin \
                /usr/include \
                /usr/lib \
                /usr/lib/x86_64-linux-gnu

              # Preserve the symlink layout expected by Clang and llvm-ar.
              for tool in \
                clang clang++ clang-22 clang-cpp \
                llc opt \
                llvm-ar llvm-as llvm-config llvm-dis llvm-link llvm-objdump \
                llvm-ranlib
              do
                cp -d --preserve=mode "${source_dir}/bin/${tool}" /usr/bin/
              done

              # Mesa links selected LLVM components statically. Keep every
              # libLLVM component so llvm-config can resolve arbitrary target
              # sets without depending on how Mesa's component list evolves.
              cp -d --preserve=mode "${source_dir}"/lib/libLLVM*.a /usr/lib/
              cp -d --preserve=mode "${source_dir}"/lib/libclang*.a /usr/lib/
              cp -d --preserve=mode "${source_dir}"/lib/libPolly*.a /usr/lib/
              # The official binary release was configured against Debian's
              # multiarch path and records it in LLVMConfig.cmake. Supply the
              # same archive there so static consumers can use the metadata
              # without host filesystem fallbacks.
              cp --preserve=mode \
                /usr/lib/libzstd.a \
                /usr/lib/x86_64-linux-gnu/libzstd.a
              # Mesa's Rust bindgen step loads libclang through clang-sys.
              # This shared library contains its LLVM implementation and does
              # not require a separate shared libLLVM.
              cp -d --preserve=mode "${source_dir}"/lib/libclang.so* /usr/lib/
              cp -Rd --preserve=mode "${source_dir}/include/." /usr/include/
              cp -Rd --preserve=mode "${source_dir}/lib/clang" /usr/lib/
              cp -Rd --preserve=mode "${source_dir}/lib/cmake/llvm" \
                /usr/lib/cmake/

              # The upstream export describes the complete binary
              # distribution, while this package intentionally omits large
              # unrelated command-line tools. Keep all imported library
              # targets, but remove the generated package-wide existence
              # assertion for targets no consumer requested.
              sed -i \
                '/# Loop over all imported files and verify that they actually exist/,/unset(_cmake_import_check_targets)/d' \
                /usr/lib/cmake/llvm/LLVMExports.cmake

              clang_version=$(/usr/bin/clang --version)
              llvm_version=$(/usr/bin/llvm-config --version)
              llvm_objdump_version=$(/usr/bin/llvm-objdump --version)
              llvm_link_mode=$(/usr/bin/llvm-config --shared-mode)
              printf '%s\n' "${clang_version}"
              printf '%s\n' "${llvm_objdump_version}"
              printf 'llvm-config version=%s link-mode=%s\n' \
                "${llvm_version}" "${llvm_link_mode}"
              case "${clang_version}" in
                "clang version %{version} "*) ;;
                *) echo "unexpected Clang version" >&2; exit 1 ;;
              esac
              test "${llvm_version}" = "%{version}"
              test "${llvm_link_mode}" = "static"
              test -s /usr/lib/libclang.so.22.1.8
              test -s /usr/lib/libclangBasic.a
              test -s /usr/lib/libPolly.a
              test -s /usr/lib/libPollyISL.a
              test -s /usr/lib/x86_64-linux-gnu/libzstd.a
              test -s /usr/lib/cmake/llvm/LLVMConfig.cmake
              targets=$(/usr/bin/llvm-config --targets-built)
              printf 'LLVM targets: %s\n' "${targets}"
              for target in X86 AMDGPU SPIRV
              do
                case " ${targets} " in
                  *" ${target} "*) ;;
                  *) echo "LLVM target ${target} is missing: ${targets}" >&2; exit 1 ;;
                esac
              done
              printf '%s\n' 'int llvm_bin_smoke(void) { return 0; }' |
                /usr/bin/clang -x c -c -o "@{build}/llvm-bin-smoke.o" -
              test -s "@{build}/llvm-bin-smoke.o"
            "%,
          ],
        },
      ],
      script_config = {},
    },
    inputs = {
      source = mk_src version source_object_hash,
    },
  }
  in

  {
    include [
      llvm_bin,
    ],
  }
