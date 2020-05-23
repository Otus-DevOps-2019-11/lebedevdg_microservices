output "k8s_cluster_master_version" {
  value = google_container_cluster.my_cluster.master_version
}

output "k8s_cluster_node_version" {
  value = google_container_node_pool.my_cluster_nodes.version
}

output "k8s_cluster_node_count" {
  value = google_container_node_pool.my_cluster_nodes.node_count
}
