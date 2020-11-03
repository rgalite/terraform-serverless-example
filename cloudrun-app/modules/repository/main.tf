resource "google_sourcerepo_repository" "default" {
  name    = var.name
  project = var.project_id
}
