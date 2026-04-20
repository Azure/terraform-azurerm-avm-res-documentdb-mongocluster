variable "mongo_cluster_id" {
  type        = string
  description = "The resource ID of the parent MongoDB vCore cluster."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the firewall rule. Must be unique within the cluster."
  nullable    = false

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]{1,80}$", var.name))
    error_message = "Firewall rule name must be 1-80 characters and contain only letters, numbers, underscores, or hyphens."
  }
}

variable "start_ip_address" {
  type        = string
  description = "The start IP address of the firewall rule. Must be a valid IPv4 address."
  nullable    = false

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", var.start_ip_address))
    error_message = "start_ip_address must be a valid IPv4 address."
  }
}

variable "end_ip_address" {
  type        = string
  description = "The end IP address of the firewall rule. Must be a valid IPv4 address."
  nullable    = false

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", var.end_ip_address))
    error_message = "end_ip_address must be a valid IPv4 address."
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}
