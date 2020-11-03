resource "google_vpc_access_connector" "default" {
  name          = var.name
  region        = var.region
  ip_cidr_range = var.ip_cidr_range
  network       = var.network
  project       = var.project_id
}
