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
# Pattern: create cluster WITHOUT default node pool,
# then add a managed node pool resource with your settings.
resource "google_container_cluster" "gke_cluster" {
  provider = google-beta
  name     = var.cluster_name
  location = var.location
  project  = var.project_id

  # Standard (not Autopilot): do not set enable_autopilot.
  release_channel {
    channel = "REGULAR"
  }

  # Use VPC-native (recommended). If you don't have a custom VPC/Subnet,
  # you can omit the blocks below and let GKE create ranges automatically.
  # ip_allocation_policy {}

  # If you have a custom network/subnetwork, uncomment and set these:
  # network    = var.network
  # subnetwork = var.subnetwork

  # We’ll manage node pools separately:
  remove_default_node_pool = true
  initial_node_count       = 1  # Required by API even when removing default pool.

  depends_on = [google_project_service.services]
}

############################################
# Primary Node Pool (Standard)
############################################
resource "google_container_node_pool" "primary_nodes" {
  provider = google-beta
  name     = "default-pool"
  project  = var.project_id
  location = var.location
  cluster  = google_container_cluster.gke_cluster.name

  # Start with 3 nodes; autoscaling will adjust between 1 and 5.
  node_count = 3

  node_config {
    machine_type = "e2-medium"  # ✅ belongs here

    # Broad scope is simple for demos; scope down for least-privilege in prod.
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    # Optional niceties:
    # preemptible  = true
    # disk_type    = "pd-standard"
    # disk_size_gb = 50
    # service_account = var.node_sa_email
    # labels = { env = var.env }
    # tags   = ["gke", var.env]
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # For regional clusters spanning zones, you can pin zones if you like:
  # node_locations = ["us-central1-a", "us-central1-b", "us-central1-c"]

  depends_on = [google_container_cluster.gke_cluster]
}