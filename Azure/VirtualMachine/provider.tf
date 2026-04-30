# Provider requirements. Root modules should configure `provider "azurerm" { features {} }`
# and authentication (CLI, OIDC, service principal, etc.).
terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0, < 5.0.0"
    }
  }
}
