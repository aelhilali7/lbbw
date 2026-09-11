#############################################
# Azure AI Search – Teil 1.2 Isolation je Dienst
#############################################

resource "azurerm_search_service" "rag" {
  name                = "srch-${local.name}"
  location            = azurerm_resource_group.ai.location
  resource_group_name = azurerm_resource_group.ai.name
  sku                 = "standard"
  replica_count       = 2
  partition_count     = 1
  tags                = var.tags

  # Öffentlichen Endpunkt schließen
  public_network_access_enabled = false

  # Keine API-Keys, nur RBAC (Teil 1.4)
  local_authentication_enabled = false
  authentication_failure_mode  = "http401WithBearerChallenge"

  # System-Managed Identity für Shared Private Links zu Storage und OpenAI
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_private_endpoint" "search" {
  name                = "pe-srch-${local.name}"
  location            = azurerm_resource_group.ai.location
  resource_group_name = azurerm_resource_group.ai.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-srch-${local.name}"
    private_connection_resource_id = azurerm_search_service.rag.id
    subresource_names              = ["searchService"]
    is_manual_connection           = false
  }
  # DNS-Registrierung per Policy des Plattformteams (siehe ai-services.tf).
}

#############################################
# Dienst-zu-Dienst ohne öffentlichen Endpunkt (Teil 1.2):
# Shared Private Links vom Suchdienst zu Storage (Indexer) und OpenAI (Vektorisierung).
# Die Verbindungen müssen vom Ressourcen-Owner freigegeben werden (kontrollierter Pfad).
#############################################

resource "azurerm_search_shared_private_link_service" "to_storage" {
  name               = "spl-storage-blob"
  search_service_id  = azurerm_search_service.rag.id
  subresource_name   = "blob"
  target_resource_id = azurerm_storage_account.docs.id
  request_message    = "AI Search Indexer -> Storage (Teil 1.2)"
}

resource "azurerm_search_shared_private_link_service" "to_openai" {
  name               = "spl-openai"
  search_service_id  = azurerm_search_service.rag.id
  subresource_name   = "openai_account"
  target_resource_id = azurerm_cognitive_account.openai.id
  request_message    = "AI Search integrierte Vektorisierung -> Azure OpenAI (Teil 1.2)"
}

resource "azurerm_monitor_diagnostic_setting" "search" {
  name                       = "diag-srch-${local.name}"
  target_resource_id         = azurerm_search_service.rag.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "OperationLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
