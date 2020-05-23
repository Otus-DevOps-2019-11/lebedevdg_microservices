terraform {
  required_version = "~>0.12.8"
}

provider "google" {
  version = "~>3.0"
  project = var.project
  region  = var.region
}

resource "google_container_cluster" "my_cluster" {
  name = var.cluster_name
  # region or zone
  location = var.zone
  network  = "default"

  # We can't create a cluster with no node pool defined, but we want to only use separately managed node pools
  # So we create the smallest possible default node pool and immediately delete it
  remove_default_node_pool = true
  initial_node_count       = 1

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

resource "google_container_node_pool" "my_cluster_nodes" {
  name = var.node_pool_name
  # region or zone
  location   = var.zone
  cluster    = google_container_cluster.my_cluster.name
  node_count = var.node_count

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    preemptible  = false
    machine_type = var.node_machine_type
    disk_size_gb = var.node_disk_size_gb
    disk_type    = var.node_disk_type
    tags         = var.node_tags

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring"
    ]
  }
}

resource "google_compute_firewall" "firewall_k8s_node_ports" {
  name    = "allow-k8s-node-ports-default"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = var.firewall_node_ports
  }
  direction     = "INGRESS"
  priority      = 1000
  source_ranges = var.firewall_source_ranges
  target_tags   = var.node_tags
}
