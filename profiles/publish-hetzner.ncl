# Publication profile preset for public Bobr Object Storage in Nuremberg.
# This is a profile fragment containing output_repository, not a provider.
# Compose with bobr-user.ncl and explicit pkgs/goals in the workspace profile.
# Paths are relative to that profile, not to this preset. No secrets live here;
# the default trusted key is the recipes' signing-key-1.pub.pem.
{
  output_repository = {
    create_bucket_if_missing | priority -50 = false,
    repository | priority -50 = "s3://bobr",
    endpoint_url | priority -50 = "https://nbg1.your-objectstorage.com",
    region | priority -50 = "nbg1",
    credentials_file | priority -50 = ".config/bobr/aws-credentials",
    credentials_profile | priority -50 = "bobr-hetzner",
    master_url | priority -50 = "https://bobr.nbg1.your-objectstorage.com/master",
    data_base_url | priority -50 = "https://bobr.nbg1.your-objectstorage.com/",
  },
}
