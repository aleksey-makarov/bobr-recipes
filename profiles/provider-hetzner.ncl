# One read-side provider for the public Bobr repository in Nuremberg.
# Use as an array entry, not a profile fragment:
#
#     secondaries.providers = [
#       import "bobr-recipes/profiles/provider-hetzner.ncl",
#     ],
#
# Both capabilities are enabled; ordinary overrides can disable either one.
# Paths are relative to the top-level build profile. No S3 credentials are used;
# data_base_url is obtained from the authenticated master.
{
  name | priority -50 = "hetzner",
  mappings | priority -50 = true,
  content | priority -50 = true,
  remote = {
    master_url | priority -50 = "https://bobr.nbg1.your-objectstorage.com/master",
    trusted_keys | priority -50 = ["bobr-recipes/signing-key-1.pub.pem"],
    ca_bundle | priority -50 = "",
  },
}
