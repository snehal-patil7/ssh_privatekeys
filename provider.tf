#########################################################
# Provider
#########################################################
provider "aws" {
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "art-dev02"
  region                  = var.region
}

terraform {
  backend "s3" {
    bucket                  = "147101433358-terraformstates"
    key                     = "bastion-host-instance/state"
    region                  = "eu-central-1"
    shared_credentials_file = "~/.aws/credentials"
    profile                 = "art-dev02"
    dynamodb_table          = "vfde-147101433358-tf-locks"
  }
}
