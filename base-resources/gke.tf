# Source: https://github.com/hashicorp/learn-terraform-provision-gke-cluster/
# https://learn.hashicorp.com/tutorials/terraform/gke 

#3-node admin cluster
#variable "gke_num_nodes" {
#  default     = 3
#  description = "number of gke nodes"
#}

# Config Connector, etc. 
resource "google_container_cluster" "platform" {
  project = var.project_id 
  provider = google-beta
  # name is the GKE cluster name. 
  name     = "platform-admin"
  # location is the GCP zone your GKE cluster is deployed to. 
  location = "us-central1-f"

  # Not using default node pool instead using custom node pool due to requirement of Config Sync
  remove_default_node_pool = true
  initial_node_count = 1

  #  all clusters have Workload Identity enabled, which allows you to connect 
  # a Google Service Account with specific roles to your Kubernetes Workloads. 
  # (instead of the default which is to have your GKE nodes have the default GCE 
  # service account - which has sweeping permissions on your project.)
  workload_identity_config {
    identity_namespace = "${var.project_id}.svc.id.goog"
  }

# The platfom admin cluster is enabled with Config Connector
  addons_config {
    config_connector_config {
      enabled = true
    }
  }
}

# Platform Admin cluster - node pool 
resource "google_container_node_pool" "platform-nodes" {
  project = var.project_id 
  name       = "${google_container_cluster.platform.name}-node-pool"
  location   = "us-central1-f"
  cluster    = google_container_cluster.platform.name
  node_count = var.gke_num_nodes

  # Node's API scope 
  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/cloud-platform", 
      "https://www.googleapis.com/auth/devstorage.read_only", 
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append", 
    ]

    labels = {
      env = var.project_id
    }

    machine_type = "e2-standard-4"
    tags         = ["gke-node", "${var.project_id}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

# 💻 DEVELOPMENT CLUSTER 
resource "google_container_cluster" "dev" {
  project = var.project_id 
  name     = "my-dev"
  location = "us-east1-c"

  remove_default_node_pool = true
  initial_node_count = 1

  workload_identity_config {
    identity_namespace = "${var.project_id}.svc.id.goog"
  }

}

# Dev cluster node pool
resource "google_container_node_pool" "dev-nodes" {
  project = var.project_id 
  name       = "${google_container_cluster.dev.name}-node-pool"
  location   = "us-east1-c"
  cluster    = google_container_cluster.dev.name
  node_count = var.gke_num_nodes

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/cloud-platform", 
      "https://www.googleapis.com/auth/devstorage.read_only", 
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append", 
    ]

    labels = {
      env = var.project_id
    }

    # preemptible  = true
    machine_type = "e2-standard-2"
    tags         = ["gke-node", "${var.project_id}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}