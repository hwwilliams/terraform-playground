terraform {
  # Experimental optional variable attributes.
  # https://github.com/hashicorp/terraform/issues/19898
  experiments = [module_variable_optional_attrs]
  required_providers {
    azurerm = "~> 3.17.0"
    random  = "~> 3.3.2"
  }
}

provider "azurerm" {
  skip_provider_registration = true
  features {}
}

provider "random" {}
