variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "plan_sku" { type = string, default = "P1v3" }
variable "php_version" { type = string, default = "8.2" }
variable "integration_subnet_id" { type = string }
variable "private_subnet_id" { type = string }
variable "vnet_id" { type = string }
variable "private_only" { type = bool, default = true }
variable "app_settings" {
  type    = map(string)
  default = {}
}