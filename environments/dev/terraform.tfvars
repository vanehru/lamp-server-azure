# Core
location = "eastus"
rg_name  = "rg-lamp-dev"

# Network
vnet_address_space            = ["10.10.0.0/16"]
subnet_integration_cidr       = "10.10.1.0/24"
subnet_private_endpoints_cidr = "10.10.2.0/24"

# Storage (SFTP)
storage_account_name = "stlampdev12345" # globally unique, lowercase, 3-24 chars
create_sftp_user     = true
sftp_user_name       = "cms-ingest"
sftp_home_directory  = "media"
ssh_public_keys      = ["ssh-rsa AAAA... yourkey"]

# App Service
webapp_name = "lamp-webapp-dev"
plan_sku    = "P1v3"
php_version = "8.2"

# Function
function_name             = "lamp-func-dev"
enable_eventgrid_to_queue = true

# MySQL
mysql_name           = "lamp-mysql-dev"
mysql_admin_login    = "lampadmin"
mysql_admin_password = "ChangeMe-Use-KeyVault-In-Prod!"
