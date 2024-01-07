terraform {
  backend "s3" {
    bucket = "terraformstatefilestorage"
    key    = "dev/terraform.state"
    region="us-east-1"
  }
}