# Quick Start Guide

## Overview
Complete Azure infrastructure deployment with CI/CD pipeline for a containerized .NET Razor Pages application.

## What's Included

### Infrastructure
- 7 Azure resources fully configured via Terraform
- Managed Identity for secure authentication
- Key Vault for secrets management
- SQL Server with database
- App Service with Docker container support
- Container Registry for images
- Application Insights monitoring

### CI/CD Pipeline
- Automated Docker build on code push
- Push to Azure Container Registry
- Infrastructure deployment via Terraform
- Automatic container deployment to App Service

## Getting Started

### 1. Prerequisites
- Azure Subscription with resource group `rg-user11`
- Storage account `stprotmaks` for Terraform state
- GitHub repository configured
- OIDC federation between GitHub and Azure

### 2. Configure GitHub Secrets
Navigate to repository Settings > Secrets and add:

```
AZURE_CLIENT_ID              - Your Service Principal Client ID
AZURE_CLIENT_SECRET          - Your Service Principal Client Secret
AZURE_SUBSCRIPTION_ID        - Your Azure Subscription ID
AZURE_TENANT_ID              - Your Azure AD Tenant ID
ACR_LOGIN_SERVER             - Your Container Registry login server
```

### 3. Deploy
Simply push to `main` branch:

```bash
git add .
git commit -m "Deploy infrastructure"
git push origin main
```

The pipeline will automatically:
1. Build Docker image
2. Push to Azure Container Registry
3. Deploy all infrastructure
4. Deploy container to App Service

## Key Resources

### Infrastructure Files
- `main.tf` - Complete infrastructure definition
- `variables.tf` - Input variable definitions
- `outputs.tf` - Terraform output values

### Pipeline Files
- `.github/workflows/deploy.yml` - Main CI/CD pipeline
- `.github/workflows/terraform.yml` - Legacy validation workflow

### Documentation
- `IMPLEMENTATION.md` - Detailed implementation guide
- `COMPLETION_SUMMARY.md` - Complete checklist and summary
- `README.md` - Workshop materials

## Resource Names

All resources follow the pattern `{type}-user11`:

| Resource | Name |
|----------|------|
| Managed Identity | mi-app-user11 |
| SQL Server | sqlserver-user11 |
| Database | razorpagesmoviedb |
| App Service Plan | asp-user11 |
| App Service | app-razorpages-user11 |
| Container Registry | cruser11 |
| Key Vault | kv-protmaks |
| App Insights | ai-user11 |
| Log Analytics | la-user11 |

## Verify Deployment

### Check Resources
```bash
az resource list --resource-group rg-user11 --output table
```

### Get App Service URL
```bash
az webapp show --resource-group rg-user11 --name app-razorpages-user11 \
  --query defaultHostName --output tsv
```

### View Logs
```bash
az webapp log tail --resource-group rg-user11 --name app-razorpages-user11
```

## Architecture

```
GitHub (main branch)
    ↓
Build Docker Image
    ↓
Push to ACR (Azure Container Registry)
    ↓
Deploy Infrastructure (Terraform)
    ├─ Managed Identity
    ├─ SQL Server
    ├─ Application Insights
    ├─ App Service Plan
    ├─ App Service
    ├─ Container Registry
    └─ Key Vault
    ↓
Deploy Container to App Service
    ↓
Application Running with Secure Access to:
├─ SQL Database (via connection string in Key Vault)
├─ Application Insights (via connection string in Key Vault)
└─ Container Registry (via Managed Identity)
```

## Key Features

✅ Infrastructure as Code (Terraform)
✅ Containerization (Docker)
✅ Automated CI/CD (GitHub Actions)
✅ Secure Authentication (Managed Identity)
✅ Secrets Management (Key Vault)
✅ Monitoring (Application Insights)
✅ HTTPS Only
✅ Passwordless OIDC Authentication

## Cost Optimization

- B1 App Service Plan (Basic tier) - Most cost-effective
- Basic SQL Database - Perfect for workshop
- Basic Container Registry - Single region
- 30-day retention on logs

## Security Best Practices Implemented

- ✅ Managed Identity for service-to-service authentication
- ✅ Key Vault for all sensitive configuration
- ✅ HTTPS-only connections
- ✅ Network ACLs on Key Vault
- ✅ OIDC-based GitHub authentication
- ✅ No hardcoded secrets in code/pipeline

## Troubleshooting

### Pipeline Fails
1. Check GitHub Secrets are configured
2. Verify Azure credentials have sufficient permissions
3. Review pipeline logs in GitHub Actions

### Application Doesn't Start
1. Check Key Vault access: Verify Managed Identity has "Key Vault Secrets User" role
2. Check SQL connection: Verify database firewall allows App Service
3. View logs: `az webapp log tail --resource-group rg-user11 --name app-razorpages-user11`

### Can't Access Application
1. Verify App Service is running: `az webapp show --resource-group rg-user11 --name app-razorpages-user11 --query state`
2. Check default hostname: `az webapp show --resource-group rg-user11 --name app-razorpages-user11 --query defaultHostName`
3. Review health check logs

## Next Steps

After successful deployment:

1. Configure custom domain and SSL certificate
2. Set up additional App Insights alerts
3. Configure auto-scaling policies
4. Implement automated backups
5. Set up disaster recovery

For detailed information, see `IMPLEMENTATION.md`

## Support

For issues or questions:
1. Review `IMPLEMENTATION.md` for detailed documentation
2. Check `COMPLETION_SUMMARY.md` for configuration details
3. Review Azure portal for resource health
4. Check GitHub Actions logs for pipeline issues
