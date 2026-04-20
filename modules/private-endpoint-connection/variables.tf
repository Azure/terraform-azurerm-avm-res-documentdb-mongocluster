variable "mongo_cluster_id" {
  type        = string
  description = "The resource ID of the parent MongoDB vCore cluster."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the private endpoint connection. This is typically assigned by Azure when a private endpoint is created."
  nullable    = false
}

variable "connection_state" {
  type = object({
    status           = string
    description      = optional(string, null)
    actions_required = optional(string, null)
  })
  description = <<DESCRIPTION
The private link service connection state for the private endpoint connection.

- `status` - (Required) The connection status. Possible values are `Pending`, `Approved`, or `Rejected`.
- `description` - (Optional) The reason for approval/rejection.
- `actions_required` - (Optional) A message indicating if changes on the service provider require any updates on the consumer.
DESCRIPTION
  nullable    = false

  validation {
    condition     = contains(["Pending", "Approved", "Rejected"], var.connection_state.status)
    error_message = "connection_state.status must be one of: Pending, Approved, Rejected."
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
