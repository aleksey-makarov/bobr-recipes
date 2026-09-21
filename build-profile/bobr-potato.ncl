# Local publication profile for the dedicated Bobr bucket on potato.
#
# Import this preset from the workspace's top-level `bobr.ncl`. It contains no
# secrets: only paths to credentials and the local CA are recorded here.
(import "bobr-user.ncl")
& {
  output_repository | priority -50 = {
    create_bucket_if_missing = true,

    repository = "s3://bobr",
    endpoint_url = "https://192.168.0.169:7070",
    region = "us-east-1",

    credentials_file = ".config/bobr/aws-credentials",
    credentials_profile = "bobr-potato",
    ca_bundle = ".config/bobr/local-repository-ca.cert.pem",

    master_url = "https://192.168.0.169:7070/bobr/master",
    data_base_url = "https://192.168.0.169:7070/bobr/",
  },
}
