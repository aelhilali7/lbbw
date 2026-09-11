data "azurerm_client_config" "current" {}

locals {
  name = "${var.name_prefix}-${var.environment}"
}

resource "azurerm_resource_group" "ai" {
  name     = "rg-${local.name}"
  location = var.location
  tags     = var.tags
}
