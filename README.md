# LAMP on Azure App Service (private), with SFTP-only Blob and private MySQL

This Terraform deploys:
- Azure Resource Group
- VNet with two subnets:
  - apps-integration (for App Service + Function VNet integration)
  - private-endpoints (for Private Endpoints)
- Storage Account (ADLS Gen2) with SFTP enabled, containers `media` and `packages`
  - Private Endpoint + Private DNS
  - Optional SFTP local user(s) scoped to container(s)
- App Service Plan + Linux PHP Web App (managed identity)
  - VNet integration + Private Endpoint + Private DNS
- Linux Function App (managed identity) with a Storage Queue for deployment events
  - Optional Event Grid subscription from Blob (packages) → queue
- Azure Database for MySQL Flexible Server (private only)
  - Private Endpoint + Private DNS
- Role assignments for App/Function identities to access Blob

## Layout

- modules/
  - network/
  - storage_sftp/
  - app_service/
  - function_app/
  - mysql_private/
- environments/
  - dev/ (example environment that wires everything together)

## Prereqs

- Terraform >= 1.5
- Azure CLI logged in: `az login`
- Proper subscription selected: `az account set --subscription "<SUBSCRIPTION_ID>"`
- If creating SFTP local users, have SSH public keys ready.

## Quick start

```bash
cd environments/dev
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars to set names, location, CIDRs, and MySQL admin creds

terraform init
terraform plan
terraform apply
```

Outputs will include endpoint FQDNs and resource IDs.

## SFTP access

If `private_only = true` (default), SFTP resolves to a Private Endpoint IP via `privatelink.blob.core.windows.net`.
Connect from a VM/jump host on the VNet (or via VPN/ER):

```bash
sftp -i ~/.ssh/id_rsa cms-ingest@<storageAccountName>.blob.core.windows.net
```

You’ll land in `/media` (home directory) if you configured the local user as shown.

## Deployment trigger flow (optional)

- Upload a deployment ZIP to `packages/` in the storage account (can be via SFTP).
- Event Grid (if enabled) routes blob-created events to a Storage Queue.
- The Function App implements a queue-trigger function to update the Web App (ZipDeploy or Run-From-Package).
  (Function code is not included in this baseline; infra only.)

## Security notes

- Storage, App Service, and MySQL use Private Endpoints and private DNS zones.
- The storage account disables public network access when `private_only = true`.
- App Service public network access is disabled by default; access via Private Endpoint or publish via WAF/Front Door with Private Link.
- MySQL public access is disabled.

## Next steps

- Add a WAF (Application Gateway v2 or Front Door Premium) with Private Link to publish the app safely to the internet.
- Add Function code to react to the queue (`deploy-events`) and perform ZipDeploy or set `WEBSITE_RUN_FROM_PACKAGE`.
- Consider Azure Cache for Redis for sessions and CDN for media if needed.