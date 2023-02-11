# Configure Config Sync and using Cloud Build to  deploy container apps on GKE

The example provided here is to demonstrate deployment of 2 GKE VPC-native clusters on default VPC network, enable ACM [Config Sync](https://cloud.google.com/anthos-config-management/docs/config-sync-overview) on those GKE clusters, and create [Cloud Build](https://cloud.google.com/build) trigger with [Terraform](https://www.terraform.io/)

In addition to that, the example also demonstrates on how to make use of Cloud Build to deploy sample container apps to one of the Clusters.

The following steps are with the assumption that the Google Cloud Project and Billing Account for deploying Google Cloud resources have been setup accordingly. 

If you don't have Google Cloud project, get started [here](https://cloud.google.com/gcp/) for free.

## Pre requisites

In order to use the example described here, the following is required:

1. Obtain your Google  Project ID

1. Create a VPC network (default network) in your project. You can use this [module](https://github.com/terraform-google-modules/terraform-google-network) to create a VPC network

1. Create a new GitHub repo and a connection to your own GitHub repo in Cloud Build, you can setup the new GitHub repo connection using this [guide](https://cloud.google.com/build/docs/automating-builds/build-repos-from-github#installing_gcb_app) and skip the creation of the trigger as it will be created by Terraform in this example 

## Deploying GKE Clusters, enable Config Sync, Policy Controller, and configure Cloud Build
1. Clone this repo
   ```bash
   git clone https://github.com/hyperionian/config-management.git
   ```
1. Copy and push the app-deployment/ and optionally config-root/ directory (config sync repo) to your own GitHub repo and obtain the following details from your GitHub repo. Github owner name (for example https://github.com/hyperionian, the owner is hyperionian), GitHub repo name, and branch name for triggering the build in Cloud Build.


1. Set the Google Cloud project id and project number environment variable
   ```bash
    PROJECT_ID=[PROJECT_ID]
    ```
1.  Make the necessary changes to the github_owner (Github owner name), github_repository (GitHub repo name), and branch_name (GitHub branch name) obtained from your own repo in the cloudbuild.tf file. Deploy 2 GKE clusters and a Cloud Build trigger. Optionally, you can update the sync_repo, sync_branch, and policy_dir in gke.tf file to point to your own config sync repo.

    ```bash
    # Login with user account for terraform to use
    gcloud auth application-default login

    # Make sure you are in base-resources directory
    cd base-resources
    export TF_VAR_project_id=$PROJECT_ID
    terraform init
    terraform plan
    terraform apply
    ```
    Alternatively, you can instantiate the project_id variable in terraform.tfvars file. See terraform.tfvars.example for more details.

The Terraform code will deploy 2 clusters (platform-admin and my-dev), enable Workload Identity and  assigned with necessary IAM roles (Compute and Storage Admin), assign Cloud Build with required IAM roles for deploying container apps, enable Config Sync, and Policy Controller. It uses the new Terraform resources [google_gke_hub_feature](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/gke_hub_feature), [google_hub_feature_membership](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/gke_hub_feature_membership), [google_gke_hub_membership](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/gke_hub_membership)

## GKE Config Sync

The config sync will sync the clusters with the Kubernetes objects defined in under /config-root directory (unstructured repo) of the cloned repo for namespaces configuration, resource quota configuration, and sample wordpress app deployments. To check if the config sync has synced all the configured Kubernetes objects.

1. Connect to the each cluster and check if the config sync has synced all the Kubernetes objects. Check the namespace creations.

   ```bash
   ZONE_ADMIN=[Platform ADMIN Cluster Zone]
   ZONE_DEV=[My Dev Cluster Zone]
   # Note that Platform ADMIN cluster zone is set to us-central1-f and My Dev cluster zone is set to us-east1-c in the example Terraform code

   # Connecting to platform-admin cluster
   gcloud container clusters get-credentials platform-admin --zone $ZONE_ADMIN --project $PROJECT_ID
   kubectl get namespace

   # Connecting to my-dev cluster
   gcloud container clusters get-credentials my-dev --zone $ZONE_DEV --project $PROJECT_ID
   kubectl get namespace
   ```
 The Development namespace should be created in all custers, wp namespace is created in my-dev cluster, resource quota is created in both wp and development namespaces, Wordpress pods and services are created in wp namespace

## App Deployment using Cloud Build

1. Make and push changes to your app repo created earlier based on app-deployment/ directory, it will be trigger a build in Cloud Build to deploy sample apps to a GKE cluster with External Ingress. The sample app is based on the examples provided [here](https://cloud.google.com/kubernetes-engine/docs/how-to/load-balance-ingress)

1. Test the sample app. Make sure that you are the in the right kubeconfig context for my-dev cluster.
   ```bash
   kubectl get ingress my-ingress --output yaml -n development
   ```
   The output shows the IP address of the HTTPS external Load Balancer. Test against / path by running 
   ```bash
   curl loadbalancerip
   # It should return "Hello, world!"
   curl loadbalancerip/kube
   # It should return "Hello Kubernetes!"

   ```