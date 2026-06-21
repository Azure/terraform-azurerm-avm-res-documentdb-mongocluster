variable "parent_id" {
  type        = string
  description = "Resource ID of the parent MongoDB vCore cluster."
  nullable    = false

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.DocumentDB/mongoClusters", var.parent_id))
    error_message = "parent_id must be a valid Azure MongoDB vCore cluster resource ID."
  }
}

variable "resource_types" {
  type = object({
    this = optional(string, "Microsoft.DocumentDB/mongoClusters/firewallRules@2025-09-01")
  })
  default     = {}
  description = "Optional override for the firewall rule resource type and API version."
  nullable    = false
}

variable "name" {
  type        = string
  description = "Firewall rule name. Must start with an alphanumeric character and may contain alphanumerics, hyphens, underscores and dots."
  nullable    = false

  validation {
    condition     = can(regex("^[a-zA-Z0-9][-_.a-zA-Z0-9]*$", var.name)) && length(var.name) >= 1 && length(var.name) <= 80
    error_message = "name must be 1-80 characters, start with alphanumeric, and contain only alphanumeric, -, _, . characters."
  }
}

variable "start_ip" {
  type        = string
  description = "Start IPv4 address of the firewall rule range."
  nullable    = false

  validation {
    condition     = can(regex("^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$", var.start_ip))
    error_message = "start_ip must be a valid IPv4 address."
  }
}

variable "end_ip" {
  type        = string
  description = "End IPv4 address of the firewall rule range."
  nullable    = false

  validation {
    condition     = can(regex("^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$", var.end_ip))
    error_message = "end_ip must be a valid IPv4 address."
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "Whether to emit AVM telemetry headers. Passed from the root module."
  nullable    = false
}

variable "avm_azapi_header" {
  type        = string
  default     = null
  description = "Pre-computed AVM User-Agent header string from the root module. Pass null when telemetry is disabled."
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = "Retry configuration applied to the firewall rule azapi_resource. Defaults to null (provider defaults)."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = "Per-operation timeouts applied to the firewall rule azapi_resource. Defaults to null (provider defaults)."
}
