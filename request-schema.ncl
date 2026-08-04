# The request format these recipes emit.
#
# One constant, in one file, because two readers need the same answer:
# `request.ncl` stamps it into every request, and the build driver compares it
# with what `bobr --version` reports before generating anything. Were each to
# carry its own copy, a bumped schema would silently stop being checked.
"bobr-request-v2"
