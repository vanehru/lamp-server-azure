variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "vnet_id" {
  type = string
}

variable "private_subnet_id" {
  type = string
}

variable "admin_login" {
  type = string
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "sku_name" {
  type    = string
  default = "GP_Standard_D2ds_v5"
}

variable "storage_size_gb" {
  type    = number
  default = 64
}

variable "version" {
  type    = string
  default = "8.0.21"
}
