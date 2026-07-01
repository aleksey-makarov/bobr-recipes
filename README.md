# bobr-recipes

Recipes for the [`bobr`](https://github.com/aleksey-makarov/bobr) build system,
written in [Nickel](https://nickel-lang.org/): a worked example that builds a
whole Linux root filesystem from source, starting from an OCI base image,
bootstrapping a self-hosted toolchain, and composing the result into root
filesystems and disk images.

The Nickel layer is documented in the "Recipes in Nickel" chapter of the
[`bobr` documentation](https://github.com/aleksey-makarov/bobr/tree/master/docs).

## License

This license applies to the **recipe code** in this repository, not to the
third-party software the recipes build. Packages such as glibc, coreutils, and
the rest of the GNU toolchain are fetched from their upstreams and carry their
own licenses (GPL, LGPL, and others); those are unaffected by the license here.

The recipe code is licensed under either of

- Apache License, Version 2.0 ([LICENSE-APACHE](./LICENSE-APACHE) or
  <http://www.apache.org/licenses/LICENSE-2.0>)
- MIT license ([LICENSE-MIT](./LICENSE-MIT) or
  <http://opensource.org/licenses/MIT>)

at your option.

Unless you explicitly state otherwise, any contribution intentionally submitted
for inclusion in the work by you, as defined in the Apache-2.0 license, shall be
dual licensed as above, without any additional terms or conditions.
