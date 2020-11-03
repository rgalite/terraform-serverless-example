output "trigger_id" {
  description = "The cloud build trigger id."
  value       = google_cloudbuild_trigger.default.trigger_id
}
