terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.100.0"
    }
  }
}

provider "azurerm" { features {} }

resource "azurerm_service_plan" "plan" {
  name                = "${var.name}-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.plan_sku
}

resource "azurerm_linux_web_app" "app" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.plan.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      php_version = var.php_version
    }
    vnet_route_all_enabled = true
  }

  app_settings = merge(
    {
      "WEBSITE_RUN_FROM_PACKAGE" = ""
    },
    var.app_settings
  )

  https_only = true
}

# Regional VNet integration
resource "azurerm_app_service_virtual_network_swift_connection" "integration" {
  app_service_id = azurerm_linux_web_app.app.id
  subnet_id      = var.integration_subnet_id
}

# Private DNS zone for App Service PE
resource "azurerm_private_dns_zone" "app" {
  count               = var.private_only ? 1 : 0
  name                = "privatelink.azurewebsites.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "app_link" {
  count                 = var.private_only ? 1 : 0
  name                  = "app-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.app[0].name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
}

# Private Endpoint for sites
resource "azurerm_private_endpoint" "pe_sites" {
  count               = var.private_only ? 1 : 0
  name                = "${var.name}-pe-sites"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_subnet_id

  private_service_connection {
    name                           = "sites-conn"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_linux_web_app.app.id
    subresource_names              = ["sites"]
  }
}

# Private Endpoint for scm
resource "azurerm_private_endpoint" "pe_scm" {
  count               = var.private_only ? 1 : 0
  name                = "${var.name}-pe-scm"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_subnet_id

  private_service_connection {
    name                           = "scm-conn"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_linux_web_app.app.id
    subresource_names              = ["scm"]
  }
}

resource "azurerm_private_dns_zone_group" "app_sites_zone_group" {
  count               = var.private_only ? 1 : 0
  name                = "app-sites-dns-group"
  private_endpoint_id = azurerm_private_endpoint.pe_sites[0].id

  private_dns_zone_configs {
    name                = "app-dns-config"
    private_dns_zone_id = azurerm_private_dns_zone.app[0].id
  }
}

resource "azurerm_private_dns_zone_group" "app_scm_zone_group" {
  count               = var.private_only ? 1 : 0
  name                = "app-scm-dns-group"
  private_endpoint_id = azurerm_private_endpoint.pe_scm[0].id

  private_dns_zone_configs {
    name                = "app-dns-config"
    private_dns_zone_id = azurerm_private_dns_zone.app[0].id
  }
}

# Disable public network access on the Web App when using Private Endpoints
resource "azurerm_resource_group_template_deployment" "disable_public_network" {
  count               = var.private_only ? 1 : 0
  name                = "${var.name}-disable-public"
  resource_group_name = var.resource_group_name
  deployment_mode     = "Incremental"

  template_content = jsonencode({
    "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion" = "1.0.0.0",
    "resources" = [
      {
        "type"       = "Microsoft.Web/sites",
        "apiVersion" = "2023-12-01",
        "name"       = azurerm_linux_web_app.app.name,
        "location"   = var.location,
        "properties" = {
          "publicNetworkAccess" = "Disabled"
        }
      }
    ]
  })
}