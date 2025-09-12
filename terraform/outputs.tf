output "gke_cluster_name"   { value = google_container_cluster.gke_cluster.name }
output "gke_cluster_region" { value = var.location }
output "artifact_repo_path" {
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_repo}"
}