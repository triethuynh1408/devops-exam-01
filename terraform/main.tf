provider "google" {
  project = local.project_id
  region = local.region
}

# VPC
resource "google_compute_network" "vpc" {
  name                    = "${local.project_id}"
  auto_create_subnetworks = "false"
}

# Subnet
resource "google_compute_subnetwork" "public_ap_southeast1_a" {
  name = "public-ap-southeast1-a"
  network = google_compute_network.vpc.name
  region = local.region
  ip_cidr_range = "10.0.1.0/24"
}

resource "google_compute_subnetwork" "private_ap_southeast1_a" {
  name = "private-ap-southeast1-a"
  network = google_compute_network.vpc.name
  region = local.region
  ip_cidr_range = "10.0.2.0/24"
}

resource "google_compute_subnetwork" "public_ap_southeast1_b" {
  name = "public-ap-southeast1-b"
  network = google_compute_network.vpc.name
  region = local.region
  ip_cidr_range = "10.0.3.0/24"
}

resource "google_compute_subnetwork" "private_ap_southeast1_b" {
  name = "private-ap-southeast1-b"
  network = google_compute_network.vpc.name
  region = local.region
  ip_cidr_range = "10.0.4.0/24"
}

resource "google_compute_subnetwork" "public_ap_southeast1_c" {
  name = "public-ap-southeast1-c"
  network = google_compute_network.vpc.name
  region = local.region
  ip_cidr_range = "10.0.5.0/24"
}

resource "google_compute_subnetwork" "private_ap_southeast1_c" {
  name = "private-ap-southeast1-c"
  network = google_compute_network.vpc.name
  region = local.region
  ip_cidr_range = "10.0.6.0/24"
}

resource "google_compute_nat" "nat_ap_southeast1_a" {
  name = "nat-ap-southeast1-a"
  network = google_compute_network.vpc.name
  region = local.region
  subnetwork = google_compute_subnetwork.public_ap_southeast1_a.name
}

resource "google_compute_nat" "nat_ap_southeast1_b" {
  name = "nat-ap-southeast1-b"
  network = google_compute_network.vpc.name
  region = local.region
  subnetwork = google_compute_subnetwork.public_ap_southeast1_b.name
}

resource "google_compute_nat" "nat_ap_southeast1_c" {
  name = "nat-ap-southeast1-c"
  network = google_compute_network.vpc.name
  region = local.region
  subnetwork = google_compute_subnetwork.public_ap_southeast1_c.name
}

# Route
resource "google_compute_route" "private_ap_southeast1_a" {
  name = "private-ap-southeast1-a"
  network = google_compute_network.vpc.name
  dest_range = "0.0.0.0/0"
  next_hop_gateway = google_compute_nat.nat_ap_southeast1_a.gateway
}

resource "google_compute_route" "private_ap_southeast1_b" {
  name = "private-ap-southeast1-b"
  network = google_compute_network.vpc.name
  dest_range = "0.0.0.0/0"
  next_hop_gateway = google_compute_nat.nat_ap_southeast1_b.gateway
}

resource "google_compute_route" "private_ap_southeast1_c" {
  name = "private-ap-southeast1-c"
  network = google_compute_network.vpc.name
  dest_range = "0.0.0.0/0"
  next_hop_gateway = google_compute_nat.nat_ap_southeast1_c.gateway
}

# This blocks creates the Kubernetes cluster
resource "google_container_cluster" "_" {
  name     = local.project_id
  location = local.region

  node_pool {
    name = "builtin"
  }
  lifecycle {
    ignore_changes = [node_pool]
  }
}

# Creating and attaching the node-pool to the Kubernetes Cluster
resource "google_container_node_pool" "node-pool" {
  name               = "node-pool"
  cluster            = google_container_cluster._.id
  initial_node_count = 1

  node_config {
    preemptible  = false
    machine_type = "e2-standard-4"
  }
}

# Create the cluster role binding to give the user the privileges to create resources into Kubernetes
resource "kubernetes_cluster_role_binding" "cluster-admin-binding" {
  metadata {
    name = "cluster-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "User"
    name      = "${var.email}"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "kube-system"
  }
  subject {
    kind      = "Group"
    name      = "system:masters"
    api_group = "rbac.authorization.k8s.io"
  }

  depends_on = [google_container_cluster._, google_container_node_pool.node-pool]
}

# Install ECK operator via helm-charts
resource "helm_release" "elastic" {
  name = "elastic-operator"

  repository       = "https://helm.elastic.co"
  chart            = "eck-operator"
  namespace        = "elastic-system"
  create_namespace = "true"

  depends_on = [google_container_cluster._, google_container_node_pool.node-pool, kubernetes_cluster_role_binding.cluster-admin-binding]

}

# Delay of 30s to wait until ECK operator is up and running
resource "time_sleep" "wait_30_seconds" {
  depends_on = [helm_release.elastic]

  create_duration = "30s"
}

# Create Elasticsearch manifest
resource "kubectl_manifest" "elastic_quickstart" {
    yaml_body = <<YAML
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: quickstart
spec:
  version: 8.1.3
  nodeSets:
  - name: default
    count: 3
    config:
      node.store.allow_mmap: false
YAML

  provisioner "local-exec" {
     command = "sleep 60"
  }
  depends_on = [helm_release.elastic, time_sleep.wait_30_seconds]
}

# Create Kibana manifest
resource "kubectl_manifest" "kibana_quickstart" {
    yaml_body = <<YAML
apiVersion: kibana.k8s.elastic.co/v1
kind: Kibana
metadata:
  name: quickstart
spec:
  version: 8.1.3
  count: 1
  elasticsearchRef:
    name: quickstart
YAML

  provisioner "local-exec" {
     command = "sleep 60"
  }
  depends_on = [helm_release.elastic, kubectl_manifest.elastic_quickstart]
}