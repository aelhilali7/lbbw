#############################################
# Azure OpenAI (AI Services Account) – Teil 1.2 Isolation je Dienst
#############################################

resource "azurerm_cognitive_account" "openai" {
  name                = "aoai-${local.name}"
  location            = azurerm_resource_group.ai.location
  resource_group_name = azurerm_resource_group.ai.name
  kind                = "OpenAI"
  sku_name            = "S0"
  tags                = var.tags

  # Pflicht für Private Link und Entra-ID-Authentifizierung (Teil 1.2)
  custom_subdomain_name = "aoai-${local.name}"

  # Öffentlichen Endpunkt schließen (Teil 1.1 / 1.2)
  public_network_access_enabled = false
  network_acls {
    default_action = "Deny"
    bypass         = "None"
  }

  # Keine API-Keys, nur Entra ID (Teil 1.4)
  local_auth_enabled = false

  # Der Dienst selbst darf keine ausgehenden Verbindungen ins Internet aufbauen
  outbound_network_access_restricted = true

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_cognitive_deployment" "models" {
  for_each             = var.openai_model_deployments
  name                 = each.key
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = each.value.model_name
    version = each.value.model_version
  }

  sku {
    name     = "Standard"
    capacity = each.value.capacity
  }
}

#############################################
# Private Endpoint für Azure OpenAI (Teil 1.2)
# Keine private_dns_zone_group im Code: Die DeployIfNotExists-Policy des
# Plattformteams registriert den Endpoint automatisch in den drei zentralen
# AI-DNS-Zonen (Annahme, siehe teil2.md). CAF: "If you use the
# DeployIfNotExists policy approach, you shouldn't integrate DNS in your code."
#############################################

resource "azurerm_private_endpoint" "openai" {
  name                = "pe-aoai-${local.name}"
  location            = azurerm_resource_group.ai.location
  resource_group_name = azurerm_resource_group.ai.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-aoai-${local.name}"
    private_connection_resource_id = azurerm_cognitive_account.openai.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }
}

#############################################
# Nachvollziehbarkeit: Data-Plane-Logs nach Log Analytics (Teil 1.2 / 1.4)
#############################################

resource "azurerm_monitor_diagnostic_setting" "openai" {
  name                       = "diag-aoai-${local.name}"
  target_resource_id         = azurerm_cognitive_account.openai.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "Audit"
  }

  enabled_log {
    category = "RequestResponse"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
