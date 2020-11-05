terraform {
  backend "gcs" {
    bucket = "tsf-project-factory-cloudrun-app-tfstate"
  }
}
