output "k8s_cluster_name" {
  value = google_container_cluster.my_cluster.name
}

output "k8s_cluster_endpoint" {
  value = google_container_cluster.my_cluster.endpoint
}

output "k8s_cluster_master_version" {
  value = google_container_cluster.my_cluster.master_version
}

output "k8s_cluster_node_version" {
  value = google_container_node_pool.my_cluster_nodes.version
}

output "k8s_cluster_node_count" {
  value = google_container_node_pool.my_cluster_nodes.node_count
}

output "k8s_cluster_node_machine_type" {
  value = google_container_node_pool.my_cluster_nodes.node_config[0].machine_type
}
