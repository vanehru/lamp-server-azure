variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "private_only" { type = bool, default = true }
variable "vnet_id" { type = string }
variable "private_subnet_id" { type = string }
variable "containers" {
  type    = list(string)
  default = ["media", "packages"]
}
variable "create_private_dns_zone" { type = bool, default = true }
variable "sftp_local_user_name" {
  type        = string
  default     = null
  description = "If set, create a local SFTP user with this username."
}
variable "sftp_home_directory" {
  type        = string
  default     = "media"
}
variable "sftp_permissions" {
  description = "Permissions string for the scope (e.g., rwldc)."
  type        = string
  default     = "rwldc"
}
variable "ssh_public_keys" {
  description = "List of SSH public keys for the SFTP local user."
  type        = list(string)
  default     = []
}