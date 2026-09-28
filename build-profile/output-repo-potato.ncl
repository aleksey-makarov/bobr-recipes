# Output repository preset for the dedicated Bobr bucket on potato.
#
# This is a partial build profile. Compose it with the standard user profile
# and local overrides in the workspace's top-level `bobr.ncl`:
#
#     (import "bobr-recipes/build-profile/bobr-user.ncl")
#     & (import "bobr-recipes/build-profile/output-repo-potato.ncl")
#     & {
#       output_repository.create_bucket_if_missing = false,
#     }
#
# It contains no secrets: only paths to credentials and the local CA are
# recorded here. Leaf values use a merge priority between contract defaults
# and ordinary user fields. Keeping the enclosing record at ordinary priority
# lets independent profile fragments merge recursively.
{
  output_repository = {
    create_bucket_if_missing | priority -50 = true,

    repository | priority -50 = "s3://bobr",
    endpoint_url | priority -50 = "https://192.168.0.169:7070",
    region | priority -50 = "us-east-1",

    credentials_file
      | priority -50
      = ".config/bobr/aws-credentials",
    credentials_profile | priority -50 = "bobr-potato",
    ca_bundle
      | priority -50
      = ".config/bobr/local-repository-ca.cert.pem",

    master_url
      | priority -50
      = "https://192.168.0.169:7070/bobr/master",
    data_base_url
      | priority -50
      = "https://192.168.0.169:7070/bobr/",
  },
}
