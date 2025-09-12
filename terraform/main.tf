# Enable required APIs
resource "google_project_service" "services" {
  for_each = toset([
    "container.googleapis.com",
    "artifactregistry.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "serviceusage.googleapis.com"
  ])
  project = var.project_id
  service = each.key
}

# Artifact Registry (Docker)
resource "google_artifact_registry_repository" "docker_repo" {
  location      = var.region
  repository_id = var.artifact_repo
  description   = "Docker repo for app"
  format        = "DOCKER"
  depends_on    = [google_project_service.services]
}

# GKE Autopilot (regional)
resource "google_container_cluster" "gke_cluster" {
  provider         = google-beta
  name             = var.cluster_name
  location         = var.location
  enable_autopilot = true

  release_channel { channel = "REGULAR" }
  ip_allocation_policy {}

  depends_on = [google_project_service.services]
}

# (Optional) Allow yourself cluster-admin via gcloud after apply:
# gcloud container clusters get-credentials <cluster> --region <location> --project <project-id>
