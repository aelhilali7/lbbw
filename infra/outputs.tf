output "openai_endpoint" {
  description = "Endpunkt der Azure-OpenAI-Ressource (löst im Bank-Netz auf die private IP auf)."
  value       = azurerm_cognitive_account.openai.endpoint
}

output "openai_private_ip" {
  description = "Private IP des OpenAI Private Endpoints."
  value       = azurerm_private_endpoint.openai.private_service_connection[0].private_ip_address
}

output "app_identity_client_id" {
  description = "Client-ID der Managed Identity der RAG-App."
  value       = azurerm_user_assigned_identity.app.client_id
}
