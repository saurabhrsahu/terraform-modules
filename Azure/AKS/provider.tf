# Provider requirements. The root module must configure `provider "azurerm" { features {} }`
# and authentication (CLI, OIDC, service principal, etc.).
terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.110.0, < 4.0.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.0"
    }
  }
}
