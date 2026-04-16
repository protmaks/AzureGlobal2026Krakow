# Azure Global 2026 Krakow - Implementation Guide

This document describes the implementation of the complete CI/CD pipeline and infrastructure for deploying a containerized .NET Razor Pages application to Azure.

## Architecture Overview

The implementation includes:

### Infrastructure (Terraform IaC)
- **Managed Identity**: User-assigned managed identity for secure service-to-service authentication
- **SQL Server**: Azure SQL Database for application data storage
- **Application Insights**: Monitoring and diagnostics for the application
- **App Service Plan**: B1 (Basic) tier compute for the web application
- **Azure App Service**: Containerized web application running Docker images
- **Azure Container Registry**: Private Docker image repository
- **Key Vault**: Secure secrets management for sensitive configuration

### CI/CD Pipeline (GitHub Actions)
The pipeline has three jobs that execute in sequence:

1. **build-and-push**: Builds Docker image and pushes to ACR
   - Authenticates to Azure using OIDC federation
   - Logs in to ACR
   - Builds Docker image from `src/Dockerfile`
   - Pushes image with tag `latest`

2. **deploy-infra**: Deploys all Azure resources using Terraform
   - Depends on: build-and-push
   - Initializes Terraform with Azure backend
   - Plans and applies Terraform configuration
   - Creates all infrastructure resources

3. **update-app-service**: Deploys container to App Service
   - Depends on: deploy-infra
   - Uses `azure/webapps-deploy@v2` action
   - Pulls latest image from ACR
   - Starts container in App Service

## File Structure

```
.
├── main.tf                          # Core Terraform configuration
├── variables.tf                     # Terraform variables
├── outputs.tf                       # Terraform outputs
├── .github/workflows/
│   ├── deploy.yml                  # Main CI/CD pipeline (3 jobs)
│   └── terraform.yml               # Legacy Terraform validation workflow
├── src/
│   ├── Dockerfile                  # Multi-stage Docker build
│   ├── Program.cs                  # ASP.NET Core app configuration
│   ├── appsettings.json            # App settings with Key Vault references
│   ├── appsettings.Development.json
│   └── ...                         # Other application files
└── IMPLEMENTATION.md               # This file
```

## Resource Configuration

### Naming Convention
All resources use the pattern `{type}-user11` or `{type}-protmaks` to uniquely identify them in the shared resource group.

### Resource Group
- **Name**: `rg-user11`
- **Location**: `northeurope`
- **Subscription**: Configured via GitHub Secrets

### Managed Identity
- **Name**: `mi-app-user11`
- **Purpose**: App Service authentication and authorization
- **Roles**:
  - AcrPull: Pull images from Container Registry
  - Key Vault Secrets User: Read secrets from Key Vault
  - SQL Database Contributor: Access SQL Server (configured via SQL firewall)

### SQL Server
- **Name**: `sqlserver-user11`
- **Version**: 12.0 (SQL Server 2019)
- **Admin User**: `azureuser`
- **Database**: `razorpagesmoviedb`
- **Edition**: Basic (cost-optimized for workshop)
- **Public Network Access**: Enabled for simplicity
- **Firewall**: Allows Azure Services and deployed App Service IP

### Application Insights
- **Name**: `ai-user11`
- **Log Analytics Workspace**: `la-user11`
- **Retention**: 30 days
- **Purpose**: Monitor application performance, logs, and metrics
- **Connection String**: Stored in Key Vault and referenced by App Service

### App Service Plan
- **Name**: `asp-user11`
- **SKU**: B1 (Basic) - 1 vCPU, 1.75 GB RAM
- **OS**: Linux (required for container deployment)
- **Purpose**: Compute resources for App Service

### App Service
- **Name**: `app-razorpages-user11`
- **Runtime**: Docker Container (custom)
- **Identity**: System-assigned (links to Managed Identity)
- **Health Check**: `/status` endpoint
- **Configuration**:
  - Always On: Enabled
  - HTTPS Only: Enabled
  - HTTP2: Enabled
  - FTPS: Disabled

### Container Registry
- **Name**: `cruser11`
- **SKU**: Basic
- **Purpose**: Host Docker image for App Service
- **Access**: 
  - Managed Identity: Write access (push)
  - App Service: Pull access via Managed Identity

### Key Vault
- **Name**: `kv-protmaks`
- **SKU**: Standard
- **Network Access**: Allow AzureServices, deny by default
- **Secrets**:
  - `SqlConnectionString`: SQL Server connection details
  - `ApplicationInsightsConnectionString`: App Insights key
- **Access**: Managed Identity with "Key Vault Secrets User" role

## Environment Configuration

### GitHub Secrets Required
These must be configured in the GitHub repository settings:

```
AZURE_CLIENT_ID              - Service Principal or Managed Identity Client ID
AZURE_CLIENT_SECRET          - Service Principal Client Secret (alternative to OIDC)
AZURE_SUBSCRIPTION_ID        - Azure Subscription ID
AZURE_TENANT_ID              - Azure AD Tenant ID
ACR_LOGIN_SERVER             - Container Registry login server (e.g., cruser11.azurecr.io)
```

### Application Environment Variables
The App Service is configured with the following environment variables:

**Docker Configuration:**
- `DOCKER_REGISTRY_SERVER_URL`: ACR login server URL
- `DOCKER_ENABLE_CI`: Enable continuous integration (true)
- `DOCKER_CUSTOM_IMAGE_NAME`: Full path to Docker image in ACR
- `WEBSITES_ENABLE_APP_SERVICE_STORAGE`: Disable local storage (false)

**Application Settings:**
- `ApplicationInsights__ConnectionString`: References Key Vault secret
- `ConnectionStrings__RazorPagesMovieContext`: References Key Vault secret
- `ASPNETCORE_ENVIRONMENT`: Production
- `ASPNETCORE_URLS`: http://+:8080

### Key Vault References
Environment variables that reference Key Vault use the Azure App Service syntax:
```
@Microsoft.KeyVault(SecretUri=https://kv-protmaks.vault.azure.net/secrets/{secret-name}/)
```

This allows App Service to automatically retrieve secrets without storing them as plaintext.

## Docker Container

### Build Process
The Dockerfile uses multi-stage builds for optimization:

1. **Build Stage**: Compile .NET application
   - Base: `mcr.microsoft.com/dotnet/sdk:8.0`
   - Restores NuGet packages
   - Builds in Release mode

2. **Publish Stage**: Create optimable artifacts
   - Publishes to `/app/publish`
   - No app host (portable across platforms)

3. **Runtime Stage**: Final image
   - Base: `mcr.microsoft.com/dotnet/aspnet:8.0`
   - Copies published app
   - Exposes port 8080
   - Sets ASPNETCORE_ENVIRONMENT=Development
   - Runs: `dotnet RazorPagesMovie.dll`

### Image Naming
- **Repository**: `{acr-name}.azurecr.io/razorpages-movie`
- **Tag**: `latest` (updated on each push)
- **Full Image**: `cruser11.azurecr.io/razorpages-movie:latest`

## Database

### Schema Initialization
The application automatically applies Entity Framework migrations on startup:

```csharp
context.Database.Migrate();  // Program.cs line 45
```

### Connection String
The connection string is retrieved from Key Vault and includes:
- SQL Server FQDN
- Database: razorpagesmoviedb
- Authentication: SQL Server (username/password)
- Encryption: Required
- Timeout: 30 seconds

## Terraform Modules

All modules are sourced from: `https://github.com/pchylak/global_azure_2026_ccoe`

### Module Reference
Each module uses the git source with semantic versioning:
```hcl
source = "git::https://github.com/pchylak/global_azure_2026_ccoe.git?ref=module-name/v1.0.0"
```

### Module Dependencies
- Managed Identity: No dependencies
- SQL Server: No direct dependencies
- Application Insights: No direct dependencies
- App Service Plan: No direct dependencies
- Container Registry: No direct dependencies
- Key Vault: Depends on outputs from other modules for secret values
- App Service: Depends on all other modules for configuration

## Deployment Instructions

### Prerequisites
1. Fork/clone this repository to GitHub
2. Create a resource group in Azure (e.g., `rg-user11`)
3. Create a storage account for Terraform state
4. Set up GitHub Secrets with Azure credentials

### Manual Deployment (first time)
```bash
# Initialize Terraform
terraform init \
  -backend-config="resource_group_name=rg-user11" \
  -backend-config="storage_account_name=stprotmaks" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=terraform.tfstate"

# Validate configuration
terraform validate

# Plan deployment
terraform plan

# Apply configuration
terraform apply
```

### Automated Deployment
Push to `main` branch to trigger the GitHub Actions pipeline:
```bash
git push origin main
```

The pipeline will:
1. Build Docker image
2. Push to ACR
3. Deploy infrastructure
4. Deploy container to App Service

## Verification

### Check Infrastructure
```bash
# List created resources
az resource list --resource-group rg-user11 --output table

# Get App Service URL
az webapp show --resource-group rg-user11 --name app-razorpages-user11 \
  --query defaultHostName --output tsv
```

### Check Container
```bash
# View App Service logs
az webapp log tail --resource-group rg-user11 --name app-razorpages-user11
```

### Check Application
Navigate to the App Service URL and verify the Razor Pages application loads correctly.

## Security Considerations

1. **Managed Identity**: Uses user-assigned identity for explicit control and better auditability
2. **Key Vault**: All secrets (connection strings, keys) stored securely
3. **Network**: Key Vault allows only Azure Services by default
4. **HTTPS**: App Service configured for HTTPS only
5. **OIDC**: GitHub Actions uses OIDC for authentication (instead of secrets)
6. **Secrets in Workflows**: All sensitive values passed through encrypted GitHub Secrets

## Cost Optimization

- **App Service Plan**: B1 (Basic) tier is most cost-effective
- **SQL Database**: Basic edition with autoscaling disabled
- **Container Registry**: Basic SKU (single replica, no geo-replication)
- **Application Insights**: 30-day retention (adjust as needed)

## Troubleshooting

### Pipeline Failures

**ACR Login Failed**
- Ensure Managed Identity has AcrPush role on ACR
- Verify ACR name in GitHub Secrets

**Terraform Apply Failed**
- Check GitHub Secrets are set correctly
- Verify resource group exists and is accessible
- Review Terraform state in storage account

**App Service Container Issues**
- Check container logs: `az webapp log tail`
- Verify connection strings in Key Vault
- Check App Service MSI has Key Vault Secrets User role

### Application Not Starting

**Database Connection Error**
- Verify SQL Server firewall allows App Service IP
- Check connection string in Key Vault
- Ensure database exists and migrations succeeded

**Key Vault Access Denied**
- Verify App Service MSI is assigned
- Check MSI has "Key Vault Secrets User" role
- Verify Key Vault network ACL allows AzureServices

## Next Steps

1. Configure custom domain and SSL certificate
2. Add additional App Insights alerts and dashboards
3. Implement auto-scaling for App Service Plan
4. Set up Application Gateway for load balancing
5. Configure backup and disaster recovery
6. Implement CI/CD for application code changes
