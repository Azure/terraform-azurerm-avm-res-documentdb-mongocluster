output "test_private_cluster_id" {
  description = "Mongo cluster ID for private endpoint example."
  value       = module.test_private.mongo_cluster_id
}

