# main
provider "aws" {
  region  = "eu-west-1"
  profile = "default"
}

terraform {
  backend "s3" {
    bucket  = "davidov-k8s"
    key     = "test-eks/terraform.tfstate"
    region  = "eu-west-1"
    profile = "default"
  }
}
