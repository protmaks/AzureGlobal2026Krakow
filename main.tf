terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}

provider "random" {}

# Generate SQL admin password for Key Vault
resource "random_password" "sql_admin" {
  length  = 36
  special = true
}

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-user11"
    storage_account_name = "stprotmaks"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

# ============================================================================
# Managed Identity - for app service to access Key Vault, SQL, ACR
# ============================================================================
module "managed_identity" {
  source = "git::https://github.com/pchylak/global_azure_2026_ccoe.git?ref=managed_identity/v1.0.0"

  name = "mi-app-user11"
  resource_group = {
    name     = "rg-user11"
    location = "northeurope"
  }
  tags = {
    environment = "production"
    project     = "razorpages-movie"
  }
}

# ============================================================================
# SQL Server - Database for application data
# ============================================================================
module "mssql_server" {
  source = "git::https://github.com/pchylak/global_azure_2026_ccoe.git?ref=mssql_server/v1.0.0"

  sql_server_name       = "sqlserver-user11"
  sql_server_admin      = "azureuser"
  sql_server_version    = "12.0"
  public_network_access = true

  resource_group = {
    name     = "rg-user11"
    location = "northeurope"
  }

  databases = [
    {
      name                 = "razorpagesmoviedb"
      size                 = 2
      sku                  = "Basic"
      storage_account_type = "Geo"
      collation            = "SQL_Latin1_General_CP1_CI_AS"
    }
  ]
}

# ============================================================================
# Application Insights - Monitoring and diagnostics
# ============================================================================
module "application_insights" {
  source = "git::https://github.com/pchylak/global_azure_2026_ccoe.git?ref=application_insights/v1.0.0"

  log_analytics_name        = "la-user11"
  application_insights_name = "ai-user11"
  retention_in_days         = 30

  resource_group = {
    name     = "rg-user11"
    location = "northeurope"
  }

  tags = {
    environment = "production"
    project     = "razorpages-movie"
  }
}

# ============================================================================
# App Service Plan - Compute for the web app (B1 Basic tier)
# ============================================================================
module "app_service_plan" {
  source = "git::https://github.com/pchylak/global_azure_2026_ccoe.git?ref=service_plan/v1.0.0"

  app_service_plan_name = "asp-user11"
  sku_name              = "B1"

  resource_group = {
    name     = "rg-user11"
    location = "northeurope"
  }

  tags = {
    environment = "production"
    project     = "razorpages-movie"
  }
}

# ============================================================================
# Container Registry - For Docker image storage
# ============================================================================
module "container_registry" {
  source = "git::https://github.com/pchylak/global_azure_2026_ccoe.git?ref=container_registry/v1.0.0"

  container_registry_name = "cruser11"
  sku                     = "Basic"
  write_access            = []

  resource_group = {
    name     = "rg-user11"
    location = "northeurope"
  }

  tags = {
    environment = "production"
    project     = "razorpages-movie"
  }
}

# Grant Managed Identity write access to Container Registry
resource "azurerm_role_assignment" "acr_push" {
  scope              = module.container_registry.id
  role_definition_name = "AcrPush"
  principal_id       = module.managed_identity.managed_identity_principal_id
}

# ============================================================================
# Key Vault - Reference existing Key Vault
# ============================================================================
data "azurerm_key_vault" "this" {
  name                = "protmaks"
  resource_group_name = "rg-user11"
}

# Grant Managed Identity permission to read secrets
resource "azurerm_role_assignment" "keyvault_secrets_user" {
  scope              = data.azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id       = module.managed_identity.managed_identity_principal_id
}

# Store SQL connection string in Key Vault
resource "azurerm_key_vault_secret" "sql_connection_string" {
  name         = "SqlConnectionString"
  value        = "Server=tcp:${module.mssql_server.server.fully_qualified_domain_name},1433;Initial Catalog=razorpagesmoviedb;Persist Security Info=False;User ID=${module.mssql_server.server.administrator_login};Password=${random_password.sql_admin.result};MultipleActiveResultSets=False;Encrypt=True;Connection Timeout=30;"
  key_vault_id = data.azurerm_key_vault.this.id

  depends_on = [
    azurerm_role_assignment.keyvault_secrets_user,
    module.mssql_server
  ]
}

# Store Application Insights connection string in Key Vault
resource "azurerm_key_vault_secret" "app_insights_connection_string" {
  name         = "ApplicationInsightsConnectionString"
  value        = module.application_insights.connection_string
  key_vault_id = data.azurerm_key_vault.this.id

  depends_on = [
    azurerm_role_assignment.keyvault_secrets_user,
    module.application_insights
  ]
}

# ============================================================================
# App Service - Web application
# ============================================================================
module "app_service" {
  source = "git::https://github.com/pchylak/global_azure_2026_ccoe.git?ref=app_service/v1.0.0"

  app_service_name    = "app-razorpages-user11"
  app_service_plan_id = module.app_service_plan.app_service_plan.id
  identity_id         = module.managed_identity.managed_identity_id
  identity_client_id  = module.managed_identity.managed_identity_client_id

  resource_group = {
    name     = "rg-user11"
    location = "northeurope"
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE"       = "false"
    "DOCKER_REGISTRY_SERVER_URL"                = "https://${module.container_registry.login_server}"
    "DOCKER_ENABLE_CI"                          = "true"
    "DOCKER_CUSTOM_IMAGE_NAME"                  = "${module.container_registry.login_server}/razorpages-movie:latest"
    "ApplicationInsights__ConnectionString"     = "@Microsoft.KeyVault(SecretUri=${data.azurerm_key_vault.this.vault_uri}secrets/ApplicationInsightsConnectionString/)"
    "ConnectionStrings__RazorPagesMovieContext" = "@Microsoft.KeyVault(SecretUri=${data.azurerm_key_vault.this.vault_uri}secrets/SqlConnectionString/)"
    "ASPNETCORE_ENVIRONMENT"                    = "Production"
    "ASPNETCORE_URLS"                           = "http://+:8080"
  }

  health_check_path                 = "/status"
  health_check_eviction_time_in_min = 5
  ftps                              = "Disabled"
  always_on                         = true
  https_only                        = true
  http2_enabled                     = true

  tags = {
    environment = "production"
    project     = "razorpages-movie"
  }
 
  depends_on = [
    azurerm_key_vault_secret.sql_connection_string,
    azurerm_key_vault_secret.app_insights_connection_string,
    module.mssql_server,
    module.application_insights
  ]
}
