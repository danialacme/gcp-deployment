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
  location       = var.region
  repository_id  = var.artifact_repo
  description    = "Docker repo for app"
  format         = "DOCKER"
  depends_on     = [google_project_service.services]
}

# GKE Standard Cluster
resource "google_container_cluster" "gke_cluster" {
  provider       = google-beta # Keep google-beta if you need features not yet in the stable provider, otherwise you can switch to 'google'
  name           = var.cluster_name # You might want to rename this, e.g., "${var.cluster_name}-standard" for clarity
  location       = var.location # For Standard, this can be a zone or a region. If you want a regional cluster, ensure var.location is a region name.
  project        = var.project_id

  # No enable_autopilot = true. This is what defines it as a Standard cluster.
  # If you want a regional cluster, ensure location is a region, and GKE will create regional control planes.

  release_channel { channel = "REGULAR" }

  # Define the default node pool for the Standard cluster
  # You can customize machine_type, node_count, autoscaling, etc.
  # For a regional cluster, node pools can span zones within that region.
  node_pool {
    name         = "default-pool" # A name for your primary node pool
    node_count   = 3              # Starting with 3 nodes. Adjust as needed.
    machine_type = "e2-medium"    # A cost-effective machine type. Adjust as needed.

    # Optional: Configure node autoscaling for the node pool
    autoscaling {
      min_node_count = 1
      max_node_count = 5 # Adjust the max based on your expected load
    }

    # Optional: Configure node management (auto-upgrade, auto-repair)
    management {
      auto_repair  = true
      auto_upgrade = true
    }
  }

  # If you were using ip_allocation_policy for Autopilot, you might want to
  # configure it for Standard VPC-native clusters too, or remove it if not needed.
  # For Standard, it's often defined via `ip_allocation_policy` or `subnetwork`
  # and `network` configurations.
  # Example:
  # ip_allocation_policy {
  #   cluster_ipv4_cidr_block  = "10.4.0.0/14"
  #   services_ipv4_cidr_block = "10.4.112.0/20"
  # }

  # Remove ip_allocation_policy if you are not using VPC-native or if your network
  # configuration handles IP allocation differently.
  # If you had an explicit network/subnetwork, ensure they are referenced here.

  # If your previous cluster was regional, keep `location` as a region.
  # For Standard clusters, `node_pool` can be zonal or regional depending on
  # how you configure the cluster's `location` and the `node_pool`'s `zones` attribute.
  # Since your previous `location` was `var.location`, which is likely a region,
  # Terraform will try to make it a regional cluster with nodes managed across zones.

  depends_on = [google_project_service.services]
}

# (Optional) Allow yourself cluster-admin via gcloud after apply:
# gcloud container clusters get-credentials <cluster_name> --region <location> --project <project-id>
# Or if it's a zonal cluster:
# gcloud container clusters get-credentials <cluster_name> --zone <zone> --project <project-id>