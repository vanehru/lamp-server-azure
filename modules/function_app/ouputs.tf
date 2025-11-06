output "functionapp_id" { value = azurerm_linux_function_app.func.id }
output "functionapp_name" { value = azurerm_linux_function_app.func.name }
output "principal_id" { value = azurerm_linux_function_app.func.identity[0].principal_id }
output "queue_id" { value = azurerm_storage_queue.deploy_events.id }