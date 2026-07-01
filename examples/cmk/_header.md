# Customer-managed key (CMK) encryption

This example provisions a Cosmos DB for MongoDB vCore cluster encrypted with a
customer-managed key (CMK) stored in Azure Key Vault, using a user-assigned managed
identity to access the key.

> [!IMPORTANT]
> On Cosmos DB for MongoDB vCore, `customer_managed_key`, the `managed_identities`
> that back it, `storage_type`, and `create_mode` are **create-time-only** properties.
> They must be supplied when the cluster is first created and cannot be enabled or
> changed on an existing cluster. The module surfaces this through
> `replace_triggers_external_values`, so changing any of these on an existing cluster
> yields an explicit `# forces replacement` plan (destroy + create) instead of a
> doomed in-place update that Azure rejects. To adopt CMK on an already-provisioned
> cluster, create a new CMK-enabled cluster and migrate/restore your data into it.
