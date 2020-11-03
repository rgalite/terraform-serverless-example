resource "google_cloudbuild_trigger" "default" {
  project = var.project_id

  trigger_template {
    branch_name = "main"
    repo_name   = var.repository_name
    dir         = "."
  }

  build {
    step {
      name = "gcr.io/cloud-builders/docker"
      args = ["build", "-t", "gcr.io/${var.project_id}/app:$COMMIT_SHA", "."]
    }

    step {
      name = "gcr.io/cloud-builders/docker"
      args = [
        "push",
        "gcr.io/${var.project_id}/app:$COMMIT_SHA"
      ]
    }

    step {
      name       = "gcr.io/google.com/cloudsdktool/cloud-sdk"
      entrypoint = "gcloud"
      args = [
        "run",
        "deploy",
        "${var.project_id}-srv",
        "--image",
        "gcr.io/${var.project_id}/app:$COMMIT_SHA",
        "--region",
        var.region,
        "--platform",
        "managed"
      ]
    }
  }
}
