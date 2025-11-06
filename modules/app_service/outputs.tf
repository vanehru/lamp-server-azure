output "service_plan_id" { value = azurerm_service_plan.plan.id }
output "webapp_id" { value = azurerm_linux_web_app.app.id }
output "webapp_name" { value = azurerm_linux_web_app.app.name }
output "principal_id" { value = azurerm_linux_web_app.app.identity[0].principal_id }
output "web_pe_id" { value = azurerm_private_endpoint.pe_sites.id }
output "scm_pe_id" { value = azurerm_private_endpoint.pe_scm.id }