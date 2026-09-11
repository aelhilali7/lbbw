#############################################
# Storage Account (Quelldokumente) – Teil 1.2
#############################################

resource "azurerm_storage_account" "docs" {
  name                     = replace("st${local.name}docs", "-", "")
  location                 = azurerm_resource_group.ai.location
  resource_group_name      = azurerm_resource_group.ai.name
  account_tier             = "Standard"
  account_replication_type = "ZRS"
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"
  tags                     = var.tags

  # Öffentlichen Endpunkt schließen
  public_network_access_enabled = false
  network_rules {
    default_action = "Deny"
    bypass         = ["None"]
  }

  # Keine Shared Keys, nur Entra ID (Teil 1.4); kein anonymer Blob-Zugriff
  shared_access_key_enabled       = false
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 30
    }
  }
}

resource "azurerm_private_endpoint" "storage_blob" {
  name                = "pe-st-${local.name}-blob"
  location            = azurerm_resource_group.ai.location
  resource_group_name = azurerm_resource_group.ai.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-st-${local.name}-blob"
    private_connection_resource_id = azurerm_storage_account.docs.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
  # DNS-Registrierung per Policy des Plattformteams (siehe ai-services.tf).
}

#############################################
# Key Vault – Teil 1.2
#############################################

resource "azurerm_key_vault" "ai" {
  name                = "kv-${local.name}"
  location            = azurerm_resource_group.ai.location
  resource_group_name = azurerm_resource_group.ai.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "premium"
  tags                = var.tags

  # Nur RBAC, keine Access Policies (Teil 1.4)
  rbac_authorization_enabled = true

  # Öffentlichen Endpunkt schließen
  public_network_access_enabled = false
  network_acls {
    default_action = "Deny"
    bypass         = "None"
  }

  purge_protection_enabled   = true
  soft_delete_retention_days = 90
}

resource "azurerm_private_endpoint" "keyvault" {
  name                = "pe-kv-${local.name}"
  location            = azurerm_resource_group.ai.location
  resource_group_name = azurerm_resource_group.ai.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-kv-${local.name}"
    private_connection_resource_id = azurerm_key_vault.ai.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }
  # DNS-Registrierung per Policy des Plattformteams (siehe ai-services.tf).
}
