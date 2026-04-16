output "app_service_name" {
  value       = module.app_service.webapp.name
  description = "Name of the App Service"
}

output "resource_group_name" {
  value       = "rg-user11"
  description = "Resource group name"
}

output "container_registry_login_server" {
  value       = module.container_registry.login_server
  description = "Container Registry login server URL"
}

output "container_registry_name" {
  value       = module.container_registry.name
  description = "Container Registry name"
}

output "managed_identity_client_id" {
  value       = module.managed_identity.managed_identity_client_id
  description = "Managed Identity client ID"
}

output "keyvault_id" {
  value       = data.azurerm_key_vault.this.id
  description = "Key Vault ID"
}

output "sql_server_fqdn" {
  value       = module.mssql_server.server.fully_qualified_domain_name
  description = "SQL Server FQDN"
}

output "application_insights_instrumentation_key" {
  value       = module.application_insights.instrumentation_key
  sensitive   = true
  description = "Application Insights instrumentation key"
}

output "application_insights_connection_string" {
  value       = module.application_insights.connection_string
  sensitive   = true
  description = "Application Insights connection string"
}
