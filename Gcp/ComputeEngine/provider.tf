# Provider requirements for this module. Root modules should configure
# `provider "google" { ... }` with credentials, project, and region.
terraform {
  required_version = ">= 1.3.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.47.0, < 8.0.0"
    }
  }
}
