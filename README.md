# Configure Config Sync and deploy container apps on GKE

This article is to demonstrate how to deploy 2 GKE clusters and enable ACM [Config Sync](https://cloud.google.com/anthos-config-management/docs/config-sync-overview) feature with Terraform

In addition to that, the article also demonstrates on how to make use of Cloud Build to deploy sample container apps to one of the Clusters


## Deploy 2 Clusters using Terraform 
The following steps are with the assumption that the Google Cloud Project and Billing Account for deploying Google Cloud resources have been setup accordingly

1. Clone this repo
   ```bash
   git clone https://github.com/hyperionian/config-management.git
   ```
1. Set the Google Cloud project id and project number environment variable
   ```bash
    PROJECT_ID=[PROJECT_ID]
    PROJECT_NUMBER=[PROJECT_NUMBER]
    ```
1. Deploy the 2 clusters using Terraform

    ```bash
    # Login with user account for terraform to use
    gcloud auth application-default login

    # change to /base-resources directory
    cd base-resources
    export TF_VAR_project_id=$PROJECT_ID
    export TF_VAR_project_number=$PROJECT_NUMBER
    terraform init
    terraform plan
    terraform apply
    ```
The Terraform template will deploy 2 clusters (platform-admin and my-dev), enable Workload Identity and  assigned with necessary IAM roles (Compute and Storage Admin), assign Cloud Build with required IAM roles for deploying container apps, enable Config Sync, and Policy Controller. It uses the new Terraform resources [google_gke_hub_feature](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/gke_hub_feature), [google_hub_feature_membership](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/gke_hub_feature_membership), [google_gke_hub_membership](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/gke_hub_membership)

## Config Sync

The config sync will sync the clusters with the unstructured repo under /config-root directory for namespace configuration. Test the config sync by running the following command

 ```bash
 kubectl get namespaces 
 ```
 against the clusters.
 
 The Development namespace should be created in all custers, wp namespace is created in gkeacm-my-dev cluster, resource quota is created in both wp and development namespace, Wordpress pods and services are created in wp namespace


## App Deployment

1. Configure the CloudBuild with the build config file under /app-deployment directory. The build config file contains build steps and arguments for deploying simple web apps documented in Configuring Ingres for external load balancing [How-to guides](https://cloud.google.com/kubernetes-engine/docs/how-to/load-balance-ingress)

1. Test the deployments
   ```bash
   kubectl get ingress my-ingress --output yaml
   ```
   The output shows the IP address of the HTTPS external Load Balancer. Test against / path by running 
   ```bash
   curl loadbalancerip
   ```