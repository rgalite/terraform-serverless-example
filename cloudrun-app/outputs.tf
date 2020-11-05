output "project_id" {
  value = module.project.project_id
}

output "repository_url" {
  description = "The cloud source repository name."
  value       = module.repository.url
}

output "service_url" {
  description = "The cloud run url service."
  value       = google_cloud_run_service.default.status[0].url
}
