variable "location" {
  type    = string
  default = "eastus"
}

variable "rg_name" {
  type    = string
  default = "rg-lamp-dev"
}

variable "vnet_address_space" {
  type    = list(string)
  default = ["10.10.0.0/16"]
}

variable "subnet_integration_cidr" {
  type    = string
  default = "10.10.1.0/24"
}

variable "subnet_private_endpoints_cidr" {
  type    = string
  default = "10.10.2.0/24"
}

variable "storage_account_name" {
  type = string
}

variable "create_sftp_user" {
  type    = bool
  default = true
}

variable "sftp_user_name" {
  type    = string
  default = "cms-ingest"
}

variable "sftp_home_directory" {
  type    = string
  default = "media"
}

variable "ssh_public_keys" {
  type    = list(string)
  default = []
}

variable "webapp_name" {
  type    = string
  default = "lamp-webapp-dev"
}

variable "plan_sku" {
  type    = string
  default = "P1v3"
}

variable "php_version" {
  type    = string
  default = "8.2"
}

variable "function_name" {
  type    = string
  default = "lamp-func-dev"
}

variable "enable_eventgrid_to_queue" {
  type    = bool
  default = true
}

variable "mysql_name" {
  type    = string
  default = "lamp-mysql-dev"
}

variable "mysql_admin_login" {
  type    = string
  default = "lampadmin"
}

variable "mysql_admin_password" {
  type      = string
  sensitive = true
}
