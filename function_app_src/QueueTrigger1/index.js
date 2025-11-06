// Queue-triggered function for Event Grid -> Storage Queue messages
// Purpose: parse blob-created event from 'packages' container and demonstrate
// how you'd either set WEBSITE_RUN_FROM_PACKAGE or call ZipDeploy.
// NOTE: This is a scaffold with TODOs. It logs inputs safely.

import { DefaultAzureCredential } from "@azure/identity";
import { WebSiteManagementClient } from "@azure/arm-appservice";
import { BlobServiceClient } from "@azure/storage-blob";

const credential = new DefaultAzureCredential();

// Configure these via App Settings for the Function App
const SUBSCRIPTION_ID = process.env.AZ_SUBSCRIPTION_ID; // e.g., set in app settings
const RESOURCE_GROUP = process.env.AZ_RESOURCE_GROUP;   // resource group of the Web App
const WEB_APP_NAME   = process.env.AZ_WEB_APP_NAME;     // target Web App name
const STORAGE_ACCOUNT_NAME = process.env.AZ_STORAGE_ACCOUNT_NAME; // same as infra storage

export default async function (context, msg) {
  try {
    const body = typeof msg === "string" ? msg : (msg?.toString?.() ?? "");
    const ev = JSON.parse(body);
    // If Event Grid batch -> Storage Queue, the message may be a JSON array
    const events = Array.isArray(ev) ? ev : [ev];

    for (const e of events) {
      // Expect Microsoft.Storage.BlobCreated
      const url = e?.data?.url;
      context.log(`BlobCreated event for: ${url}`);

      if (!url) continue;

      // Example: ensure it's in 'packages' container
      if (!/\/packages\//.test(url)) {
        context.log(`Skipping non-packages blob: ${url}`);
        continue;
      }

      // TODO Option A: Run From Package by setting WEBSITE_RUN_FROM_PACKAGE to a SAS URL
      // - Function identity needs permission to update the Web App (e.g., Website Contributor on the site or RG).
      // - To create a user delegation SAS for the blob:
      //   The identity needs 'Storage Blob Data Contributor' + 'Storage Blob Delegator' roles on the storage account.
      //
      // const sasUrl = await makeUserDelegationSas(url);
      // await setRunFromPackage(sasUrl);

      // TODO Option B: ZipDeploy to Kudu
      // - Provide publishing credentials via Key Vault or app settings (not included in this scaffold).
      // - POST to https://<app>.scm.azurewebsites.net/api/zipdeploy with the ZIP content.

      context.log(`Handled event for: ${url}`);
    }
  } catch (err) {
    context.log.error("Handler error:", err);
    throw err; // ensure retry
  }
}

// Example helper: set WEBSITE_RUN_FROM_PACKAGE on the Web App
async function setRunFromPackage(sasUrl) {
  if (!SUBSCRIPTION_ID || !RESOURCE_GROUP || !WEB_APP_NAME) {
    throw new Error("Missing AZ_SUBSCRIPTION_ID/AZ_RESOURCE_GROUP/AZ_WEB_APP_NAME app settings");
    }
  const client = new WebSiteManagementClient(credential, SUBSCRIPTION_ID);
  const site = await client.webApps.get(RESOURCE_GROUP, WEB_APP_NAME);
  const current = site.siteConfig?.appSettings ?? [];
  const appSettings = Object.fromEntries(current.map(kv => [kv.name, kv.value]));
  appSettings["WEBSITE_RUN_FROM_PACKAGE"] = sasUrl;
  await client.webApps.updateApplicationSettings(RESOURCE_GROUP, WEB_APP_NAME, {
    properties: appSettings
  });
  // Optionally restart
  await client.webApps.restart(RESOURCE_GROUP, WEB_APP_NAME);
}

// Example helper: create a user delegation SAS for a blob URL
async function makeUserDelegationSas(blobUrl) {
  // Requires roles: Storage Blob Data Contributor + Storage Blob Delegator on the storage account
  const serviceUrl = `https://${STORAGE_ACCOUNT_NAME}.blob.core.windows.net`;
  const blobService = new BlobServiceClient(serviceUrl, credential);
  const key = await blobService.getUserDelegationKey(new Date(), new Date(Date.now() + 60 * 60 * 1000));
  // Build SAS here (left as an exercise or use @azure/storage-blob generateBlobSASQueryParameters)
  // Return full SAS URL for WEBSITE_RUN_FROM_PACKAGE
  return blobUrl; // placeholder
}