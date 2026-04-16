# Setup Instructions - Local Development & Deployment

## Overview

This project is designed to run primarily in **GitHub Actions** with automated CI/CD. Local Terraform execution requires Azure authentication setup.

## Local Development Setup (Optional)

If you want to run Terraform locally for testing/development:

### 1. Install Azure CLI
```bash
# macOS
brew install azure-cli

# Windows
winget install Microsoft.AzureCLI

# Linux
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

### 2. Login to Azure
```bash
az login
```

This will open a browser for interactive login. Complete the authentication.

### 3. Set Subscription (if you have multiple)
```bash
az account set --subscription <SUBSCRIPTION_ID>
```

### 4. Export Variables for Terraform
```bash
export ARM_SUBSCRIPTION_ID="<subscription-id>"
export ARM_TENANT_ID="<tenant-id>"
export ARM_CLIENT_ID="<service-principal-id>"
export ARM_CLIENT_SECRET="<service-principal-secret>"
```

Or use interactive login:
```bash
export ARM_USE_AZ_CLI=true
```

### 5. Initialize Terraform
```bash
terraform init \
  -backend-config="resource_group_name=rg-user11" \
  -backend-config="storage_account_name=stprotmaks" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=terraform.tfstate"
```

### 6. Validate Configuration
```bash
terraform validate
```

### 7. Plan Deployment
```bash
terraform plan -out=tfplan
```

### 8. Apply Changes
```bash
terraform apply tfplan
```

## GitHub Actions Deployment (Recommended)

The implementation is optimized for **GitHub Actions** with automatic deployment on push to `main` branch.

### Prerequisites

1. **Azure Subscription** with resource group `rg-user11`
2. **Storage Account** `stprotmaks` for Terraform state
3. **GitHub Repository** with the code
4. **OIDC Federation** configured (GitHub → Azure)

### Configure GitHub Secrets

Navigate to your repository:
- **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add these secrets:

```
AZURE_CLIENT_ID
  Value: Your Service Principal Client ID or Managed Identity Client ID

AZURE_CLIENT_SECRET
  Value: Your Service Principal Client Secret
  (Not needed if using OIDC federation)

AZURE_SUBSCRIPTION_ID
  Value: Your Azure Subscription ID

AZURE_TENANT_ID
  Value: Your Azure AD Tenant ID

ACR_LOGIN_SERVER
  Value: Your Container Registry login server (e.g., cruser11.azurecr.io)
```

### Deploy via GitHub Actions

Simply push to the `main` branch:

```bash
git add .
git commit -m "Deploy infrastructure"
git push origin main
```

The pipeline will automatically:
1. ✓ Build Docker image
2. ✓ Push to Azure Container Registry
3. ✓ Deploy infrastructure (Terraform)
4. ✓ Deploy container to App Service

Monitor progress in **GitHub** → **Actions** tab.

## Troubleshooting

### "Please run 'az login' to setup account"

**Cause**: Terraform is trying to connect to Azure but authentication is not configured.

**Solution**: Run `az login` and export `ARM_USE_AZ_CLI=true`:
```bash
az login
export ARM_USE_AZ_CLI=true
terraform init
```

### "Module not installed"

**Cause**: Terraform modules haven't been downloaded yet.

**Solution**: Run `terraform init` with proper Azure credentials configured.

### "Resource Group not found"

**Cause**: The resource group `rg-user11` doesn't exist in your subscription.

**Solution**: Create it in Azure Portal or via Azure CLI:
```bash
az group create \
  --name rg-user11 \
  --location northeurope
```

### "Storage Account not found"

**Cause**: The storage account `stprotmaks` doesn't exist for state storage.

**Solution**: Create it in Azure Portal or via Azure CLI:
```bash
az storage account create \
  --name stprotmaks \
  --resource-group rg-user11 \
  --location northeurope \
  --sku Standard_LRS
```

Then create a container:
```bash
az storage container create \
  --account-name stprotmaks \
  --name tfstate
```

### Pipeline Fails in GitHub Actions

Check the workflow logs:
1. Go to **Actions** tab
2. Click on the failed workflow
3. Click on the failed job
4. Review logs to identify the issue

Common issues:
- GitHub Secrets not configured
- Azure credentials expired
- Resource limits exceeded
- Firewall/network issues

## Service Principal Setup (Alternative to OIDC)

If you don't want to use OIDC federation:

```bash
# Create Service Principal
az ad sp create-for-rbac \
  --name "github-terraform" \
  --role Contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID>
```

This will output:
```json
{
  "appId": "...",           # Use as AZURE_CLIENT_ID
  "password": "...",        # Use as AZURE_CLIENT_SECRET
  "tenant": "..."           # Use as AZURE_TENANT_ID
}
```

Add these values to GitHub Secrets.

## OIDC Federation Setup (Recommended)

OIDC federation allows GitHub Actions to authenticate to Azure without storing credentials as secrets.

### Step 1: Create App Registration

```bash
az ad app create --display-name "github-terraform"
```

Note the `appId` from output.

### Step 2: Create Service Principal

```bash
az ad sp create --id <APP_ID>
```

### Step 3: Add Federated Credentials

```bash
az ad app federated-credential create \
  --id <APP_ID> \
  --parameters '{
    "name": "github-actions",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:YOUR_USERNAME/YOUR_REPO:ref:refs/heads/main",
    "description": "GitHub Actions",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

Replace `YOUR_USERNAME/YOUR_REPO` with your actual GitHub repository path.

### Step 4: Assign Roles

```bash
az role assignment create \
  --assignee <APP_ID> \
  --role Contributor \
  --scope /subscriptions/<SUBSCRIPTION_ID>
```

### Step 5: Add GitHub Secrets

Add to your repository secrets:
- `AZURE_CLIENT_ID`: The app ID
- `AZURE_SUBSCRIPTION_ID`: Your subscription ID
- `AZURE_TENANT_ID`: Your tenant ID
- `ACR_LOGIN_SERVER`: Your Container Registry URL

No `AZURE_CLIENT_SECRET` needed with OIDC!

## Verify Deployment

After the pipeline completes, verify everything was created:

### Check Resources
```bash
az resource list --resource-group rg-user11 --output table
```

### Get App Service URL
```bash
az webapp show \
  --resource-group rg-user11 \
  --name app-razorpages-user11 \
  --query defaultHostName \
  --output tsv
```

### View App Service Logs
```bash
az webapp log tail \
  --resource-group rg-user11 \
  --name app-razorpages-user11
```

### Check Container Status
```bash
az webapp config container show \
  --resource-group rg-user11 \
  --name app-razorpages-user11
```

## Next Steps

1. **Verify All Resources**: Check Azure Portal for created resources
2. **Test Application**: Navigate to App Service URL
3. **Monitor**: Check Application Insights for metrics
4. **Configure DNS**: Set up custom domain if needed
5. **Scale**: Adjust App Service Plan SKU for production

## Support

For issues:
1. Check **IMPLEMENTATION.md** for detailed documentation
2. Review GitHub Actions logs for specific errors
3. Verify all prerequisites are met
4. Check Azure Portal for resource status
5. Review Azure CLI output for error details

## More Information

- **Terraform Documentation**: https://www.terraform.io/docs
- **Azure CLI Documentation**: https://docs.microsoft.com/cli/azure
- **GitHub Actions**: https://docs.github.com/actions
- **Azure OIDC in GitHub**: https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect
