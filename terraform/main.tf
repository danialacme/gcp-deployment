############################################
# Enable required APIs
############################################
resource "google_project_service" "services" {
  for_each = toset([
    "container.googleapis.com",
    "artifactregistry.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "serviceusage.googleapis.com",
  ])
  project = var.project_id
  service = each.key
}

############################################
# Artifact Registry (Docker)
############################################
resource "google_artifact_registry_repository" "docker_repo" {
  location      = var.region
  repository_id = var.artifact_repo
  description   = "Docker repo for app"
  format        = "DOCKER"

  depends_on = [google_project_service.services]
}

############################################
# GKE Standard Cluster (no Autopilot)
############################################
resource "google_container_cluster" "gke_cluster" {
  provider = google-beta
  name     = var.cluster_name
  location = var.location   # can be a REGION (for regional cluster) or ZONE
  project  = var.project_id

  release_channel {
    channel = "REGULAR"
  }

  # Remove the default pool; we’ll define a custom one
  remove_default_node_pool = true
  initial_node_count       = 1  # required even if removing default

  depends_on = [google_project_service.services]
}

############################################
# Primary Node Pool (2–3 nodes with autoscaling)
############################################
resource "google_container_node_pool" "primary_nodes" {
  provider = google-beta
  name     = "default-pool"
  project  = var.project_id
  location = var.location
  cluster  = google_container_cluster.gke_cluster.name

  # This is the starting number of nodes PER ZONE (if regional)
  node_count = 2

  node_config {
    machine_type = "e2-medium"
    disk_type    = "pd-standard"  # ✅ avoid SSD quota issue
    disk_size_gb = 50             # smaller, cost-effective disks

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  autoscaling {
    min_node_count = 2
    max_node_count = 3   # ✅ allow scaling up to 3 nodes
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  depends_on = [google_container_cluster.gke_cluster]
}