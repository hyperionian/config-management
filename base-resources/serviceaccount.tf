
# Create GCP Service Account and K8S Service Account to GKE Platform admin cluster, annotate K8S SA to GCP SA, and assign K8S SA as workloadIdentityUser role using workload-identity module 
# Refer to https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/tree/v16.1.0/modules/workload-identity

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.platform.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.platform.master_auth.0.cluster_ca_certificate)
}

module "workload-identity" {
  source     = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  name       = "web-service"
  namespace  = "default"
  project_id = var.project_id
  use_existing_k8s_sa = false
  roles      = ["roles/storage.admin", "roles/compute.admin"]
}