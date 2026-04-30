# Provider requirements. Root modules should configure `provider "aws" { ... }`
# with region and credentials (env vars, profile, OIDC, etc.).
terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
  }
}
