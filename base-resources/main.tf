/**
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# Enable Anthos Config Management features on Platform Admin Cluster

resource "google_gke_hub_membership" "membership" {
  provider      = google-beta
  membership_id = "membership-hub"
  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${google_container_cluster.platform.id}"
      
    }
  }
}

resource "google_gke_hub_membership" "membership_dev" {
  provider      = google-beta
  membership_id = "membership-dev"
  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${google_container_cluster.dev.id}"
      
    }
  }
}
resource "google_gke_hub_feature" "configmanagement_acm_feature" {
  name     = "configmanagement"
  location = "global"
  provider = google-beta
}

resource "google_gke_hub_feature_membership" "feature_member" {
  provider   = google-beta
  location   = "global"
  feature    = "configmanagement"
  membership = google_gke_hub_membership.membership.membership_id
  configmanagement {
    version = "1.8.0"
    config_sync {
      source_format = "unstructured"
      git {
        sync_repo   = var.sync_repo
        sync_branch = var.sync_branch
        policy_dir  = var.policy_dir
        secret_type = "none"
      }
    }
    policy_controller {
      enabled                    = true
      template_library_installed = true
      referential_rules_enabled  = true
    }
  }
  depends_on = [
    google_gke_hub_feature.configmanagement_acm_feature
  ]
}

resource "google_gke_hub_feature_membership" "feature_member_dev" {
  provider   = google-beta
  location   = "global"
  feature    = "configmanagement"
  membership = google_gke_hub_membership.membership_dev.membership_id
  configmanagement {
    version = "1.8.0"
    config_sync {
      source_format = "unstructured"
      git {
        sync_repo   = var.sync_repo
        sync_branch = var.sync_branch
        policy_dir  = var.policy_dir
        secret_type = "none"
      }
    }
    policy_controller {
      enabled                    = true
      template_library_installed = true
      referential_rules_enabled  = true
    }
  }
  depends_on = [
    google_gke_hub_feature.configmanagement_acm_feature
  ]
}