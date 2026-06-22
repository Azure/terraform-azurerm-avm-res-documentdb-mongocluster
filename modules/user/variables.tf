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
    this = optional(string, "Microsoft.DocumentDB/mongoClusters/users@2025-09-01")
  })
  default     = {}
  description = "Optional override for the user resource type and API version."
  nullable    = false
}

variable "name" {
  type        = string
  description = <<DESCRIPTION
User name. For NativeAuth users this is the login name (1-63 chars, alphanumeric and hyphens).
For MicrosoftEntraID users this must be the Entra principal's object ID (GUID).
DESCRIPTION
  nullable    = false

  validation {
    condition     = can(regex("^[a-zA-Z0-9\\-]{1,63}$", var.name))
    error_message = "name must be 1-63 characters and contain only alphanumeric characters and hyphens."
  }
}

variable "roles" {
  type = list(object({
    db   = string
    role = string
  }))
  description = <<DESCRIPTION
Database roles assigned to the user. Each entry requires:

- `db`   - The database scope (e.g. 'admin').
- `role` - The role to assign. Currently only 'root' is supported.
DESCRIPTION
  nullable    = false

  validation {
    condition     = length(var.roles) > 0
    error_message = "At least one role must be assigned."
  }
  validation {
    condition     = alltrue([for r in var.roles : r.role == "root"])
    error_message = "Only the 'root' role is currently supported by the API."
  }
}

variable "identity_provider" {
  type = object({
    type = string
    properties = optional(object({
      principal_type = string
    }), null)
  })
  default     = null
  description = <<DESCRIPTION
(Optional) Identity provider configuration for the user.

- `type`                      - Identity provider type. Currently only 'MicrosoftEntraID' is supported.
- `properties.principal_type` - (Required for MicrosoftEntraID) Entra principal type: 'servicePrincipal' or 'user'.

When null, the API creates a native-auth user (password-based).
DESCRIPTION

  validation {
    condition     = var.identity_provider == null || var.identity_provider.type == "MicrosoftEntraID"
    error_message = "identity_provider.type must be 'MicrosoftEntraID'."
  }
  validation {
    condition = var.identity_provider == null || (
      var.identity_provider.properties != null &&
      contains(["servicePrincipal", "user"], var.identity_provider.properties.principal_type)
    )
    error_message = "identity_provider.properties.principal_type must be set to 'servicePrincipal' or 'user' when identity_provider is specified."
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
  description = "Retry configuration applied to the user azapi_resource. Defaults to null (provider defaults)."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = "Per-operation timeouts applied to the user azapi_resource. Defaults to null (provider defaults)."
}
