#  Give Cloud Build permissions to deploy to GKE 

# Assign Cloud Build's service account permissions to deploy to GKE ("Kubernetes Engine Developer" role)

variable "project_number" {
  type        = string
  description = "the project number"
  default     = ""
}

resource "google_project_iam_binding" "cloud-build-iam-binding" {
  project = var.project_id
  role    = "roles/container.developer"

  members = [
    "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com",
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
