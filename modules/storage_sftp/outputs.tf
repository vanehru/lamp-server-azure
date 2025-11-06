output "storage_account_id" { value = azurerm_storage_account.sa.id }
output "storage_account_name" { value = azurerm_storage_account.sa.name }
output "blob_private_endpoint_id" { value = azurerm_private_endpoint.pe_blob.id }
output "private_dns_zone_blob_id" {
  value       = try(azurerm_private_dns_zone.blob[0].id, null)
  description = "ID of privatelink.blob.core.windows.net zone if created here."
}