output "webapp_name" { value = module.app_service.webapp_name }
output "storage_account_name" { value = module.storage_sftp.storage_account_name }
output "mysql_fqdn" { value = module.mysql.mysql_fqdn }
output "deploy_queue_id" { value = module.function_app.queue_id }
