terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # Annahme: Remote State liegt in einem Storage Account der Landing Zone,
  # erreichbar nur über Private Endpoint. Backend-Konfiguration wird per
  # `terraform init -backend-config=...` aus der Pipeline übergeben.
  backend "azurerm" {}
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
  # Authentifizierung: Workload Identity Federation (OIDC) aus der Pipeline,
  # kein Client Secret. Siehe Teil 1.4 und Teil 4.
  use_oidc = true
}
