variable "name" {
  description = "The name of the resource."
  type        = string
}

variable "network" {
  type        = string
  description = "Name of a VPC network."
}

variable "ip_cidr_range" {
  type        = string
  description = "The range of internal addresses that follows RFC 4632 notation."
}

variable "region" {
  type        = string
  description = "Region where the VPC Access connector resides"
}

variable "project_id" {
  type        = string
  description = "The ID of the project to which resources will be applied."
}
