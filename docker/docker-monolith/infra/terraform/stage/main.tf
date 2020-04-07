terraform {
  required_version = "~> 0.12.0"
}
provider "google" {
  version = "2.15"
  # ID проекта
  project = var.project
  region  = var.region
}


module "microservices-docker" {
  source           = "../modules/microservices-docker"
  zone             = var.zone
  docker_image   = var.docker_image
  enable_provision = false
}

module "vpc" {
  source        = "../modules/vpc"
  source_ranges = ["0.0.0.0/0"]

}

resource "google_compute_project_metadata_item" "default" {
  key     = "ssh-keys"
  value   = "appuser:${file(var.public_key_path)}\nappuser1:${file(var.public_key_path)}\nappuser2:${file(var.public_key_path)}"
  project = var.project
}
