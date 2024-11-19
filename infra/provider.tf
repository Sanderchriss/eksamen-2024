terraform {
  required_version = ">= 1.9.0"
  backend "s3" {
    bucket         = "pgr301-2024-terraform-state"
    key            = "lambda-infra/terraform.tfstate"
    region         = "eu-west-1" # Endre til regionen du bruker
    encrypt        = true
  }
}

provider "aws" {
  version = "~> 5.74.0"
  region  = "eu-west-1" # Endre hvis nødvendig
}
