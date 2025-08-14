############################################################
# Diagnostic Settings (Azure Monitor) via AzAPI
############################################################

resource "azapi_resource" "diagnostic_setting" {
  for_each = var.diagnostic_settings

  name      = coalesce(each.value.name, "ds-${var.name}-${each.key}")
  parent_id = azapi_resource.mongo_cluster.id
  type      = "Microsoft.Insights/diagnosticSettings@2021-05-01-preview"
  # Build the properties dynamically, omitting nulls to satisfy the ARM schema
  body = jsonencode({
    properties = merge(
      // Logs (categories + groups)
      (length(try(each.value.log_categories, [])) + length(try(each.value.log_groups, [])) > 0)
      ? {
        logs = concat(
          [for cat in try(each.value.log_categories, []) : {
            category        = cat
            enabled         = true
            retentionPolicy = { enabled = false, days = 0 }
          }],
          [for grp in try(each.value.log_groups, []) : {
            categoryGroup   = grp
            enabled         = true
            retentionPolicy = { enabled = false, days = 0 }
          }]
        )
      }
      : {},

      // Metrics (categories)
      (length(try(each.value.metric_categories, [])) > 0)
      ? {
        metrics = [for cat in try(each.value.metric_categories, []) : {
          category        = cat
          enabled         = true
          retentionPolicy = { enabled = false, days = 0 }
        }]
      }
      : {},

      // Sinks
      try(each.value.workspace_resource_id, null) != null ? { workspaceId = each.value.workspace_resource_id } : {},
      try(each.value.storage_account_resource_id, null) != null ? { storageAccountId = each.value.storage_account_resource_id } : {},
      try(each.value.event_hub_authorization_rule_resource_id, null) != null ? { eventHubAuthorizationRuleId = each.value.event_hub_authorization_rule_resource_id } : {},
      try(each.value.event_hub_name, null) != null ? { eventHubName = each.value.event_hub_name } : {},
      try(each.value.log_analytics_destination_type, null) != null ? { logAnalyticsDestinationType = each.value.log_analytics_destination_type } : {}
    )
  })
  schema_validation_enabled = true
}
