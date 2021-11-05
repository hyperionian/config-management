#  Give Cloud Build permissions to deploy to GKE 

# Assign Cloud Build's service account permissions to deploy to GKE ("Kubernetes Engine Developer" role)

variable "project_number" {
  type        = string
  description = "the project number"
}
variable "github_owner" {
  description = "Name of the GitHub Repository Owner."
  type        = string
  default     = "hyperionian"
}

variable "github_repository" {
  description = "Name of the GitHub Repository."
  type        = string
  default     = "config-management"
}

variable "branch_name" {
  description = "Example branch name used to trigger builds."
  type        = string
  default     = "main"
}

resource "google_project_iam_binding" "cloud-build-iam-binding" {
  project = var.project_id
  role    = "roles/container.developer"

  members = [
    "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com",
  ]
  depends_on = [
    module.enabled_google_apis
  ]
}
resource "google_cloudbuild_trigger" "app-deployment-trigger" {
  github {
    owner = var.github_owner
    name  = var.github_repository
    push {
      branch = var.branch_name
    }
}
  filename = "cloudbuild-dev.yaml"
  depends_on = [
    google_project_iam_binding.cloud.build.iam.binding
  ]
}


# Allows Cloud Build to commit to a user's Github account using a github token secret, 

#resource "google_project_iam_binding" "cloud-build-iam-binding-secrets" {
#  project = var.project_id
#  role    = "roles/secretmanager.secretAccessor"

 # members = [
  #  "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com",
  #]
#}
