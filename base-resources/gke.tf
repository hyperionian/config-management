# https://learn.hashicorp.com/tutorials/terraform/gke 

# Enable Google APIs

module "enabled_google_apis" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 10.0"

  project_id                  = var.project_id
  disable_services_on_destroy = false

  activate_apis = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "gkehub.googleapis.com",
    "anthosconfigmanagement.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudbuild.googleapis.com",
    "secretmanager.googleapis.com",
    "storage.googleapis.com"
  ]
}

# Deploy 2 GKE clusters with VPC Native

resource "google_container_cluster" "platform" {
  project = var.project_id 
  provider = google-beta
  # name is the GKE cluster name. 
  name     = "platform-admin"
  # location is the GCP zone your GKE cluster is deployed to. 
  location = "us-central1-f"
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "10.39.0.0/21"
    services_ipv4_cidr_block = "10.10.10.0/24"
  }

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

# DEVELOPMENT CLUSTER 
resource "google_container_cluster" "dev" {
  project = var.project_id 
  name     = "my-dev"
  location = "us-east1-c"
  provider = google-beta
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "10.32.0.0/21"
    services_ipv4_cidr_block = "10.10.11.0/24"
  }
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

# Enable Config Management feature

resource "google_gke_hub_feature" "configmanagement_acm_feature" {
  name     = "configmanagement"
  location = "global"
  provider = google-beta
}

# Set up GKE clusters for Config Management

module "gkeacm" {
  source  = "./acm-gke"
  membership_id = "gkeacm-${google_container_cluster.platform.name}"
  sync_repo = "https://github.com/hyperionian/config-management"
  sync_branch = "main"
  policy_dir = "config-root"
  resource_link = "//container.googleapis.com/${google_container_cluster.platform.id}"

  depends_on = [
    google_gke_hub_feature.configmanagement_acm_feature
  ]
}

module "gkeacm_dev" {
  source  = "./acm-gke"
  membership_id = "gkeacm-${google_container_cluster.dev.name}"
  sync_repo = "https://github.com/hyperionian/config-management"
  sync_branch = "main"
  policy_dir = "config-root"
  resource_link = "//container.googleapis.com/${google_container_cluster.dev.id}"

  depends_on = [
    google_gke_hub_feature.configmanagement_acm_feature
  ]
}

module "k8s_sa_platform" {
  source = "./serviceaccounts"
  project = var.project_id
  clustername = "${google_container_cluster.platform.name}"
  clustercacert = "${google_container_cluster.platform.master_auth.0.cluster_ca_certificate}"
  k8shost = "${google_container_cluster.platform.endpoint}"
}

module "k8s_sa_dev" {
  source = "./serviceaccounts"
  project = var.project_id
  clustername = "${google_container_cluster.dev.name}"
  clustercacert = "${google_container_cluster.dev.master_auth.0.cluster_ca_certificate}"
  k8shost = "${google_container_cluster.dev.endpoint}"
}