# Recipe development and review

## Overlay invariant

Public recipes form the overlay API.  Every consumer of a public, replaceable
recipe must obtain it through the final package set (`pkgs`), never through a
module-local binding captured before overlays are applied.

Values derived from an input must follow the input actually selected by the
recipe.  Compute names, versions, paths, configuration arguments, private
build-rootfs names, and similar values from `inputs.*` (for example,
`inputs.source.version`), rather than from a duplicated local `version` or from
a sibling package-set attribute.

Module-local references are appropriate only for deliberately private
implementation nodes which are not part of the overlay API.  Do not export a
node merely to simplify internal wiring, and do not make a public node private
merely to avoid routing its consumers through `pkgs`.

## Code review rules

When modifying or reviewing recipes, check that:

- public sources, split outputs, compiler/runtime stages, aggregates, and test
  recipes are consumed through their final `pkgs` attributes;
- changing a public recipe in an overlay reaches every consumer that is meant
  to observe that change;
- builder identity and configuration follow the actual selected inputs;
- source version and content hash live on the public `_src` recipe instead of
  being duplicated on each consuming builder;
- related stages share a public source when they are intentionally updated
  together; a consumer can still replace its own `inputs.source` explicitly;
- intentionally private nodes remain local and are not mechanically exported;
- different reachable recipe definitions have different `name` values.

Recipe `name` is currently also the Nickel lowering deduplication key.  Sharing
one recipe value and name among several consumers is correct.  Two distinct
reachable definitions with the same name are not: lowering keeps one definition
without diagnosing the conflict.  An overlay that replaces only one consumer's
input while leaving the original input reachable must therefore give the
replacement a distinct name.

## Verification

- Use targeted request lowering or `bobr-build.sh --dry-run`; never export the
  complete package set as JSON.
- Test both the default graph and the relevant overlay replacement.  For an
  independently replaced input, keep the original and replacement reachable in
  the same request so name collisions and stale local references are visible.
- If a refactor is intended to preserve recipe identity, compare the affected
  BuildKeys before and after it.  A changed BuildKey must be explained by a
  semantic input change, not by rewiring alone.
