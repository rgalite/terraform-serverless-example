variable "repository_name" {
  description = "The repository's name Cloud Build will trigger the build from."
  type        = string
}

variable "project_id" {
  type        = string
  description = "The ID of the project to which resources will be applied."
}

variable "region" {
  description = "The region of the Cloud Build resources"
  type        = string
}
