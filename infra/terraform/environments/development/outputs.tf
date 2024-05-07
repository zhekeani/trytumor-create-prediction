output "ar_repositories_url" {
  value       = module.artifact_registry.repositories_url
  sensitive   = false
  description = "Artifact Registry repositories URL."
  depends_on  = [module.artifact_registry]
}