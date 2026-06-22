output "test_private_cluster_id" {
  description = "Mongo cluster ID for private endpoint example."
  value       = module.test_private.mongo_cluster_id
}

output "test_private_pe_ids" {
  description = "Private endpoint resource IDs for the test_private module (map)."
  value = try({
    for k, v in module.test_private.private_endpoints :
    k => merge(v, { tags = coalesce(v.tags, {}) })
  }, null)
}
