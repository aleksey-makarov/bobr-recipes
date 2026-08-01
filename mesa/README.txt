Updating Mesa
=============

Mesa describes its Rust subprojects with Meson wrap files rather than a
Cargo.lock. The recipe graph must know every crates.io source before a build
starts, so rust-crate-specs.ncl is generated while updating the recipe and is
committed alongside it.

To update Mesa:

1. Download the new Mesa release archive. The update script lets the host tar
   detect the compression format, so .tar.xz, .tar.gz, and .tar.bz2 archives
   are supported.
2. From the bobr-recipes root, run:

       ./mesa/update-rust-crate-specs.sh /path/to/mesa-VERSION.tar.xz

3. Review the rust-crate-specs.ncl diff. An unknown crates.io URL or malformed
   wrap is an error and must be handled explicitly rather than silently
   omitted.
4. Update version and source_object_hash for both mesa_guest and mesa in
   mesa.ncl. These fields and mesa.rust_crate_specs belong to the same upstream
   release and must be overridden together.
5. Dry-run the mesa, mesa_guest, mesa_demos, and host_bundle_test_mesa targets,
   then perform the corresponding real builds.
