Python recipes layout
======================

The recipes in this directory build Python *libraries* that exist only to
support the build: PEP 517 build backends and helper libraries (flit_core,
setuptools, packaging, wheel, six, markupsafe, jinja2, mako, pyyaml).
Each is named python-<name>.ncl and builds with the PythonModule tag -- a wheel
built with pip and installed additively into the build rootfs. They are not
shipped in the runtime image.

The interpreter itself is python.ncl. It aggregates every module in this
directory via `include`, so pkgs.ncl imports only python/python.ncl (not each
module file individually).

Rule: library vs application
----------------------------
- A Python *library* (imported by other code; no meaningful standalone
  program) belongs HERE, as python/python-<name>.ncl.

- A Python package that is a meaningful *application* (its point is an
  executable you run) belongs in the repository ROOT as an ordinary recipe
  under its own name -- even though it still builds with the PythonModule tag.
    * meson    -> ../meson.ncl      (the Meson build system)
    * docutils -> ../docutils.ncl   (used for its rst2man man-page generator)
  (ninja -> ../ninja.ncl is meson's companion, but is C++, not a Python package.)

A few libraries kept here also ship small helper scripts -- the `wheel` command,
mako-render -- yet stay because their primary identity is a library API, not a
standalone application. Promote one to the root only if it is genuinely used as
an application rather than imported.
