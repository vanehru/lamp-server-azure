# Queue-trigger deployment function (scaffold)

This sample Azure Function shows how to consume Storage Queue messages (fed by Event Grid on BlobCreated in `packages/`) and then either:
- Set `WEBSITE_RUN_FROM_PACKAGE` on the target Web App to the uploaded package SAS URL, or
- Push the package to Kudu ZipDeploy.

It is a scaffold with TODOs and environment variables you must set.

## Configure the Function App (App Settings)

Set these application settings on your Function App:
- `AZ_SUBSCRIPTION_ID` = your Azure subscription GUID
- `AZ_RESOURCE_GROUP` = resource group name containing the Web App
- `AZ_WEB_APP_NAME` = name of the target Web App
- `AZ_STORAGE_ACCOUNT_NAME` = the storage account that holds `packages/`

## Required permissions (Managed Identity of Function App)

- On the Storage Account:
  - Storage Blob Data Contributor (already granted in the Terraform baseline).
  - Storage Blob Delegator (only if you will generate User Delegation SAS for Run From Package).

- On the Web App (or its Resource Group):
  - Website Contributor (to update app settings and restart the app).

Grant these with Azure CLI:
```bash
# Storage Blob Delegator (optional, for User Delegation SAS)
az role assignment create --assignee <FUNC_PRINCIPAL_ID> \
  --role "Storage Blob Delegator" --scope <STORAGE_ACCOUNT_ID>

# Website Contributor (allow updating app settings)
az role assignment create --assignee <FUNC_PRINCIPAL_ID> \
  --role "Website Contributor" --scope <WEB_APP_ID or RG_ID>
```

## Event flow

1. You upload a ZIP package to the `packages` container (via SFTP or any method).
2. Event Grid (configured in Terraform) emits a BlobCreated event.
3. Event is delivered to the `deploy-events` Storage Queue.
4. This Function (queue trigger) runs and receives the event details.

## Implementing deployment

- Run From Package (recommended):
  1. Generate a user delegation SAS for the uploaded blob.
  2. Call Azure Resource Manager API to set `WEBSITE_RUN_FROM_PACKAGE` to the SAS URL.
  3. Restart the Web App.

- ZipDeploy:
  1. Download the ZIP from Blob with managed identity.
  2. POST to `https://<app>.scm.azurewebsites.net/api/zipdeploy`.
     - Use publishing credentials (store securely in Key Vault) or a build pipeline.
