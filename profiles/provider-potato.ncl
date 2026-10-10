# One read-side provider entry for the Bobr repository on potato.
# Use as an entry in secondaries.providers, not as a profile fragment.
# Both capabilities are enabled; ordinary overrides can disable either one.
# Paths to the signing key and private CA certificate are relative to the
# top-level build profile. Only the CA certificate is needed, not its key.
{
  name | priority -50 = "potato",
  mappings | priority -50 = true,
  content | priority -50 = true,
  remote = {
    master_url | priority -50 = "https://192.168.0.169:7070/bobr/master",
    trusted_keys | priority -50 = ["bobr-recipes/signing-key-1.pub.pem"],
    ca_bundle | priority -50 = ".config/bobr/local-repository-ca.cert.pem",
  },
}
