output "mysql_id" { value = azurerm_mysql_flexible_server.mysql.id }
output "mysql_fqdn" { value = azurerm_mysql_flexible_server.mysql.fqdn }
output "pe_id" { value = azurerm_private_endpoint.pe_mysql.id }
