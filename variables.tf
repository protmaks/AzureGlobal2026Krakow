variable "client_id" {
  type        = string
  description = "Azure Service Principal Client ID for authentication"
  sensitive   = true
}

variable "client_secret" {
  type        = string
  description = "Azure Service Principal Client Secret for authentication"
  sensitive   = true
}

variable "tenant_id" {
  type        = string
  description = "Azure Tenant ID"
  sensitive   = true
}

variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID"
  sensitive   = true
}
