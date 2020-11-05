locals {
  region = "europe-west1"
}

module "project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 9.2"

  name                = "tsf-project"
  random_project_id   = true
  org_id              = var.project_org_id
  billing_account     = var.project_billing_account
  folder_id           = var.project_folder_id
  auto_create_network = false
  activate_apis = [
    "run.googleapis.com",
    "cloudbuild.googleapis.com",
    "sourcerepo.googleapis.com",
    "sqladmin.googleapis.com",
    "servicenetworking.googleapis.com",
    "vpcaccess.googleapis.com"
  ]
  skip_gcloud_download    = true
  default_service_account = "deprivilege"
}

module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 2.5"

  project_id   = module.project.project_id
  network_name = "tsf-network"

  subnets = [
    {
      subnet_name   = "subnet-01"
      subnet_ip     = "10.10.10.0/24"
      subnet_region = local.region
    }
  ]
}

module "vpc_connector" {
  source        = "./modules/vpc_connector"
  name          = "tsf-vpc-connector"
  region        = local.region
  ip_cidr_range = "10.8.0.0/28"
  network       = module.vpc.network_name
  project_id    = module.project.project_id
}

module "database" {
  source  = "GoogleCloudPlatform/sql-db/google//modules/safer_mysql"
  version = "4.2.0"

  name                 = "db"
  project_id           = module.project.project_id
  database_version     = "MYSQL_5_7"
  region               = local.region
  zone                 = "b"
  tier                 = "db-f1-micro"
  random_instance_name = true
  vpc_network          = "projects/${module.project.project_id}/global/networks/${module.vpc.network_name}"

  depends_on = [module.database_private_access]
}

module "database_private_access" {
  source  = "GoogleCloudPlatform/sql-db/google//modules/private_service_access"
  version = "~> 4.2.0"

  project_id  = module.project.project_id
  vpc_network = module.vpc.network_name
}

module "cloudrun_sa" {
  source       = "terraform-google-modules/service-accounts/google"
  version      = "~> 3.0.1"
  project_id   = module.project.project_id
  names        = ["cloudrun"]
  display_name = "Cloud Run"
}

module "repository" {
  source     = "./modules/repository"
  name       = "${module.project.project_id}-repository"
  project_id = module.project.project_id
}

module "cloudbuild" {
  source          = "./modules/cloudbuild"
  project_id      = module.project.project_id
  repository_name = module.repository.name
  region          = local.region
}

resource "google_cloud_run_service_iam_member" "member" {
  service  = google_cloud_run_service.default.name
  location = google_cloud_run_service.default.location
  role     = "roles/run.invoker"
  member   = "allUsers"
  project  = google_cloud_run_service.default.project
}

resource "google_cloud_run_service" "default" {
  name     = "${module.project.project_id}-srv"
  location = local.region
  project  = module.project.project_id

  metadata {
    labels = {
      "gcb-trigger-id" = module.cloudbuild.trigger_id
    }
  }

  template {
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"        = "1000"
        "run.googleapis.com/cloudsql-instances"   = module.database.instance_connection_name
        "run.googleapis.com/vpc-access-connector" = module.vpc_connector.id
      }
    }

    spec {
      service_account_name = module.cloudrun_sa.email

      containers {
        image = "gcr.io/cloudrun/hello"

        env {
          name  = "INSTANCE_CONNECTION_NAME"
          value = module.database.instance_connection_name
        }

        env {
          name  = "CLOUD_SQL_CONNECTION_NAME"
          value = module.database.instance_connection_name
        }

        env {
          name  = "DB_USER"
          value = "default"
        }

        env {
          name  = "DB_PASS"
          value = module.database.generated_user_password
        }

        env {
          name  = "DB_NAME"
          value = "default"
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true

  depends_on = [
    module.cloudrun_sa,
  ]
}
