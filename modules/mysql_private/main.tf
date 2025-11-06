terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.100.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_mysql_flexible_server" "mysql" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  administrator_login           = var.admin_login
  administrator_password        = var.admin_password
  sku_name                      = var.sku_name
  version                       = var.version
  zone                          = "1"
  public_network_access_enabled = false
  backup_retention_days         = 7

  storage {
    size_gb = var.storage_size_gb
  }

  high_availability {
    mode = "Disabled"
  }
}

# Private DNS for MySQL
resource "azurerm_private_dns_zone" "mysql" {
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "mysql_link" {
  name                  = "mysql-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.mysql.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
}

# Private Endpoint
resource "azurerm_private_endpoint" "pe_mysql" {
  name                = "${var.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_subnet_id

  private_service_connection {
    name                           = "mysql-conn"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_mysql_flexible_server.mysql.id
    subresource_names              = ["mysqlServer"]
  }
}

resource "azurerm_private_dns_zone_group" "mysql_zone_group" {
  name                = "mysql-dns-group"
  private_endpoint_id = azurerm_private_endpoint.pe_mysql.id

  private_dns_zone_configs {
    name                = "mysql-zone-config"
    private_dns_zone_id = azurerm_private_dns_zone.mysql.id
  }
}
