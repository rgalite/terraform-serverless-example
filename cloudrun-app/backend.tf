terraform {
  backend "gcs" {
    bucket = "cloudrun-app-tfstate"
  }
}
