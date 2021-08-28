output "kubernetes_platform_cluster_name" {
  value       = google_container_cluster.platform.name
  description = "GKE Platform Admin Cluster Name"
}

output "kubernetes_dev_cluster_name" {
  value       = google_container_cluster.dev.name
  description = "GKE Dev Cluster Name"
}

output "kubernetes_platform_cluster_location" {
  value       = google_container_cluster.platform.location
  description = "GKE Platform Admin Cluster location"
}

output "kubernetes_dev_cluster_location" {
  value       = google_container_cluster.dev.location
  description = "GKE Dev Cluster location"
}

output "kubernetes_platform_cluster_id" {
  value       = google_container_cluster.platform.id
  description = "GKE Platform Admin Cluster ID"
}

