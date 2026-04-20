variable "mongo_cluster_id" {
  type        = string
  description = "The resource ID of the parent MongoDB vCore cluster."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the user. Must be 1-63 characters, letters, numbers, and hyphens only."
  nullable    = false

  validation {
    condition     = can(regex("^[a-zA-Z0-9\\-]{1,63}$", var.name))
    error_message = "User name must be 1-63 characters and contain only letters, numbers, or hyphens."
  }
}

variable "identity_provider" {
  type        = any
  default     = null
  description = <<DESCRIPTION
The identity provider definition for the user. This is a discriminated object type.
For a native MongoDB user, use: `{ objectType = "NativeUser" }`.
For a Microsoft Entra ID user, set the objectType accordingly.
Refer to the Azure API documentation for supported shapes.
DESCRIPTION
}

variable "roles" {
  type = list(object({
    db   = string
    role = string
  }))
  default     = []
  description = <<DESCRIPTION
A list of database roles assigned to the user. Each role contains:
- `db`   - The name of the database.
- `role` - The role name (e.g., `dbOwner`, `read`, `readWrite`).
DESCRIPTION
  nullable    = false
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
