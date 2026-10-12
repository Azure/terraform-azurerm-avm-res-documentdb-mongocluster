# terraform-azurerm-avm-res-documentdb-mongocluster

This module manages a MongoDB Cluster using vCore Architecture.

## Upgrading from v0.1.0 to v0.2.0

v0.2.0 renamed the internal cluster resource from `azapi_resource.mongo_cluster` to
`azapi_resource.this` and moved the API version to `2025-09-01`. The module now ships a
`moved` block, so upgrading no longer plans a destroy/recreate of an existing cluster — run
`terraform plan` and confirm the state is migrated in place. If you previously worked around
this with `terraform state mv`, the `moved` block is a harmless no-op.

The create-time-only properties `create_mode`, `storage_type`, and customer-managed-key
`encryption` (with its managed identity) now default to being **omitted** unless you set them,
so a plain upgrade with no new inputs produces a clean, no-op plan.

> **Note:** `create_mode`, `storage_type`, `customer_managed_key`, and `managed_identities` are
> create-time-only on Cosmos DB for MongoDB vCore. Changing any of them on an existing cluster
> forces a **replacement** (destroy + create) — Terraform will show `# forces replacement`.
> To enable CMK encryption on an already-provisioned cluster you must create a new, CMK-enabled
> cluster and migrate/restore into it; it cannot be enabled in place.

## Private endpoints

Private endpoint `lock` and `role_assignments` values are now applied; earlier versions
accepted these inputs without creating their resources. Review the additional locks and
permissions in your upgrade plan. Omitted, empty, and null inputs retain their defaults.

Existing endpoint names, network interface naming, DNS management, and per-endpoint tags
are unchanged. `resource_group_name` continues to accept a resource group **name**, not
an ARM resource ID. An omitted or null `subresource_name` retains `MongoCluster` for the
connection and leaves the static IP configuration's group unset. An omitted or null
`member_name` leaves member selection to the platform.

Endpoint role assignments use AzAPI. `skip_service_principal_aad_check` is accepted for
interface compatibility only: AzAPI does not perform the AzureRM provider's directory
check and has no corresponding ARM property. Use `principal_type` when required by Azure.
