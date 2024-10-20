# devops-exam-01

#### Features

*Every feature will be deployed via terraform*

* Install GKE (Google Kubernetes Enginee) cluster
* It will contain 1 node pool with 3 nodes (One in each zone) running on region **ap-southeast-1**
* It contains a helm provider that will be responsible to install the ECK operator
* Elasticsearch cluster with 3 nodes
* One Kibana instance

#### Requirements

Before starting you should have the following commands installed:

* terraform
* gcloud

#### Installation

First, you have to authenticate into Google Cloud console, to so run the following command

```
gcloud auth application login
```

Once you are logged it, you should export 2 variables, the Kubernetes config path AND the Google project you are going to use

```
export KUBE_CONFIG_PATH=~/.kube/config && export GOOGLE_PROJECT=<YOUR-PROJECT-NAME>
```

Now you can run

```
terraform init
```

It will load the providers and configuration. Right after that, you should run

```
terraform plan
```

It will show you everything that will be created by terraform, take a moment to check this output.
Once you are ready, you just need to run:

```
terraform apply
```

It will apply your changes. Once everything was applied, you will get an output information

Once you `port-foward` your kibana service, you can easily access it on your browser via localhost.

#### Destroy

Now, to clean up everything you just need to run

```
terraform destroy
```
