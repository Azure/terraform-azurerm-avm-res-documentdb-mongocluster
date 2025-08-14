############################################################
# Diagnostic Settings (Azure Monitor)
############################################################

resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = var.diagnostic_settings

  name                           = coalesce(each.value.name, "ds-${var.name}-${each.key}")
  target_resource_id             = azapi_resource.mongo_cluster.id
  eventhub_authorization_rule_id = try(each.value.event_hub_authorization_rule_resource_id, null)
  eventhub_name                  = try(each.value.event_hub_name, null)
  log_analytics_destination_type = try(each.value.log_analytics_destination_type, null)
  log_analytics_workspace_id     = try(each.value.workspace_resource_id, null)
  storage_account_id             = try(each.value.storage_account_resource_id, null)

  # Enable specific log categories
  dynamic "enabled_log" {
    for_each = try(each.value.log_categories, [])

    content {
      category = enabled_log.value
    }
  }
  # Enable category groups (e.g., allLogs)
  dynamic "enabled_log" {
    for_each = try(each.value.log_groups, [])

    content {
      category_group = enabled_log.value
    }
  }
  # Enable metric categories
  dynamic "metric" {
    for_each = try(each.value.metric_categories, [])

    content {
      category = metric.value
      enabled  = true
    }
  }
}
