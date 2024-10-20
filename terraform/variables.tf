locals {
  region = "ap-southeast-1"
  project_id = "devops-exam-01"
}

variable "output" {
  description = "GKE connection string"
  type        = string
  default     = "TO CONNECT TO KUBERNETES: gcloud container clusters get-credentials <KUBERNETES-NAME> --region europe-west1 --project elastic-support-k8s-dev"
}

variable "email" {
  type        = string
  description = "Please, enter your email (elastic email) or a user"
}

variable "kibana_endpoint" {
  description = "Kibana endpoint"
  type        = string
  default     = "TO CONNECT TO KIBANA: kubectl port-forward svc/<KIBANA-ENDPOINT> 5601:5601"
}