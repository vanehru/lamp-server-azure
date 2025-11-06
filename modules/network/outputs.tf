output "vnet_id" { value = azurerm_virtual_network.vnet.id }
output "subnet_integration_id" { value = azurerm_subnet.integration.id }
output "subnet_private_endpoints_id" { value = azurerm_subnet.pe.id }