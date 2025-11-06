variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "integration_subnet_id" { type = string }
variable "queue_name" { type = string, default = "deploy-events" }
variable "enable_eventgrid_to_queue" { type = bool, default = true }
variable "source_storage_account_id" {
  type        = string
  description = "Storage account ID to subscribe to (blob created in packages/)."
}
variable "source_storage_account_name" {
  type        = string
  description = "Storage account name (for subject filtering)."
}
variable "packages_container_name" {
  type        = string
  default     = "packages"
}