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
