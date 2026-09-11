#############################################
# Identitäten und Rollen – Teil 1.4 "nur die notwendigen Rechte"
#############################################

# Anwendung: User-assigned Managed Identity der RAG-App
resource "azurerm_user_assigned_identity" "app" {
  name                = "id-${local.name}-app"
  location            = azurerm_resource_group.ai.location
  resource_group_name = azurerm_resource_group.ai.name
  tags                = var.tags
}

# Technische Identität: Indexer-Job (getrennt von der App, damit die
# Chat-App den Index nie verändern kann)
resource "azurerm_user_assigned_identity" "indexer" {
  name                = "id-${local.name}-indexer"
  location            = azurerm_resource_group.ai.location
  resource_group_name = azurerm_resource_group.ai.name
  tags                = var.tags
}

#############################################
# RAG-App: nur Inferenz, nur Lesen
#############################################

resource "azurerm_role_assignment" "app_openai_user" {
  scope                = azurerm_cognitive_account.openai.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

resource "azurerm_role_assignment" "app_search_reader" {
  scope                = azurerm_search_service.rag.id
  role_definition_name = "Search Index Data Reader"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

resource "azurerm_role_assignment" "app_keyvault_secrets_user" {
  scope                = azurerm_key_vault.ai.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

#############################################
# Indexer: Dokumente lesen, Index schreiben, Embeddings berechnen
#############################################

resource "azurerm_role_assignment" "indexer_storage_reader" {
  scope                = azurerm_storage_account.docs.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.indexer.principal_id
}

resource "azurerm_role_assignment" "indexer_search_contributor" {
  scope                = azurerm_search_service.rag.id
  role_definition_name = "Search Index Data Contributor"
  principal_id         = azurerm_user_assigned_identity.indexer.principal_id
}

resource "azurerm_role_assignment" "indexer_openai_user" {
  scope                = azurerm_cognitive_account.openai.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_user_assigned_identity.indexer.principal_id
}

#############################################
# AI Search (System-Managed Identity): Shared Private Links zu Storage und OpenAI
#############################################

resource "azurerm_role_assignment" "search_storage_reader" {
  scope                = azurerm_storage_account.docs.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_search_service.rag.identity[0].principal_id
}

resource "azurerm_role_assignment" "search_openai_user" {
  scope                = azurerm_cognitive_account.openai.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_search_service.rag.identity[0].principal_id
}
