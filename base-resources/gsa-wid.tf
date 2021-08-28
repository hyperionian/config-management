
module "my-app-workload-identity" {
  source     = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  name       = "web-service"
  namespace  = "default"
  project_id = var.project_id
  roles      = ["roles/storage.Admin", "roles/compute.Admin"]
}