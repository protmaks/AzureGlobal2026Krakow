terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
provider "azurerm" {
  features {}
}

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-user11"
    storage_account_name = "stprotmaks"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

module "keyvault" {
  source = "git::https://github.com/pchylak/global_azure_2026_ccoe.git?ref=keyvault/v1.0.0"
  keyvault_name = "protmaks"
  resource_group = {
    name     = "rg-user11"
    location = "northeurope"
  }
  network_acls = {
    bypass = "AzureServices"
    default_action = "Deny"
  }
}
