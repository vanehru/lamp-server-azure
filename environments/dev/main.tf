resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
}

module "network" {
  source                        = "../../modules/network"
  name                          = "lamp"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.rg.name
  address_space                 = var.vnet_address_space
  subnet_integration_cidr       = var.subnet_integration_cidr
  subnet_private_endpoints_cidr = var.subnet_private_endpoints_cidr
}

module "storage_sftp" {
  source                  = "../../modules/storage_sftp"
  name                    = var.storage_account_name
  location                = var.location
  resource_group_name     = azurerm_resource_group.rg.name
  private_only            = true
  vnet_id                 = module.network.vnet_id
  private_subnet_id       = module.network.subnet_private_endpoints_id
  containers              = ["media", "packages"]
  create_private_dns_zone = true

  sftp_local_user_name = var.create_sftp_user ? var.sftp_user_name : null
  sftp_home_directory  = var.sftp_home_directory
  ssh_public_keys      = var.ssh_public_keys
}

module "app_service" {
  source                = "../../modules/app_service"
  name                  = var.webapp_name
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  plan_sku              = var.plan_sku
  php_version           = var.php_version
  integration_subnet_id = module.network.subnet_integration_id
  private_subnet_id     = module.network.subnet_private_endpoints_id
  vnet_id               = module.network.vnet_id
  private_only          = true
  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = ""
  }
}

module "function_app" {
  source                      = "../../modules/function_app"
  name                        = var.function_name
  location                    = var.location
  resource_group_name         = azurerm_resource_group.rg.name
  integration_subnet_id       = module.network.subnet_integration_id
  queue_name                  = "deploy-events"
  enable_eventgrid_to_queue   = var.enable_eventgrid_to_queue
  source_storage_account_id   = module.storage_sftp.storage_account_id
  source_storage_account_name = module.storage_sftp.storage_account_name
  packages_container_name     = "packages"
}

module "mysql" {
  source              = "../../modules/mysql_private"
  name                = var.mysql_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  vnet_id             = module.network.vnet_id
  private_subnet_id   = module.network.subnet_private_endpoints_id
  admin_login         = var.mysql_admin_login
  admin_password      = var.mysql_admin_password
}

# Role assignments: App + Function identities to Storage Blob Data Contributor
data "azurerm_role_definition" "blob_contrib" {
  name  = "Storage Blob Data Contributor"
  scope = module.storage_sftp.storage_account_id
}

resource "azurerm_role_assignment" "web_blob_contrib" {
  scope              = module.storage_sftp.storage_account_id
  role_definition_id = data.azurerm_role_definition.blob_contrib.id
  principal_id       = module.app_service.principal_id
  depends_on         = [module.app_service, module.storage_sftp]
}

resource "azurerm_role_assignment" "func_blob_contrib" {
  scope              = module.storage_sftp.storage_account_id
  role_definition_id = data.azurerm_role_definition.blob_contrib.id
  principal_id       = module.function_app.principal_id
  depends_on         = [module.function_app, module.storage_sftp]
}
