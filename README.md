# Terraform GCP Web Server Infrastructure

This project deploys a highly available web server infrastructure on Google Cloud Platform (GCP) using Terraform. It sets up a network, a managed instance group of web servers, and a global load balancer to distribute traffic.

## Project Overview

The infrastructure is designed to be modular, scalable, and reproducible. It meets the following key requirements:

- **Modular Design:** Resources are segregated into `network` and `compute` modules for clarity and reusability.
- **High Availability:** A managed instance group with 3 instances is deployed behind a global load balancer to ensure the application is resilient.
- **Automated Image Creation:** A temporary VM is created, configured with an Apache web server, and then used to create a custom image. This image is then used as the source for the production instances.
- **Secure Networking:** Firewall rules are configured to allow HTTP traffic from the internet and SSH traffic from a specified IP range. Health check traffic from Google's systems is also explicitly allowed.
- **State Management:** The Terraform state is configured to be stored remotely and securely in a Google Cloud Storage (GCS) bucket.

## Prerequisites

Before you begin, ensure you have the following installed and configured:

1.  **Terraform:** [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
2.  **Google Cloud SDK:** [Install gcloud CLI](https://cloud.google.com/sdk/docs/install)
3.  **GCP Project:** A Google Cloud Platform project with billing enabled.
4.  **Authentication:** Authenticate the gcloud CLI with your GCP account:
    ```bash
    gcloud auth login
    gcloud auth application-default login
    ```
5.  **SSH Key:** An SSH key pair in your `~/.ssh/` directory (e.g., `id_rsa` and `id_rsa.pub`). If you don't have one, you can generate it with `ssh-keygen -t rsa`.

## Project Structure

The repository is organized into the following structure:

```
.
├── main.tf                 # Main Terraform configuration, ties modules together
├── variables.tf            # Defines variables for the project
├── outputs.tf              # Defines outputs from the root module
├── providers.tf            # Configures the GCP provider and backend state
├── modules/
│   ├── compute/            # Compute module (VMs, images, instance groups)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── network/            # Network module (VPC, subnets, firewall, load balancer)
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── README.md               # This file
```

## How to Deploy

### 1. Clone the Repository

Clone this repository to your local machine.

### 2. Configure Variables

Create a file named `terraform.tfvars` in the root of the project and add your GCP project ID:

```terraform
# terraform.tfvars
project_id = "your-gcp-project-id"
```

You can also override other variables defined in `variables.tf` in this file, such as `region`, `zone`, or `allowed_ip_ranges`.

### 3. Set up the GCS Backend

The Terraform state is stored in a GCS bucket for persistence and collaboration. Create a GCS bucket for this purpose:

```bash
# Replace "your-unique-bucket-name" with a globally unique name
gsutil mb gs://your-unique-bucket-name
```

Then, update the `backend "gcs"` block in `providers.tf` with your bucket name.

### 4. Initialize Terraform

Run `terraform init` to initialize the project, download the necessary providers, and configure the backend.

```bash
terraform init
```

### 5. Plan and Apply

Run `terraform plan` to see the execution plan and verify the resources that will be created.

```bash
terraform plan
```

If the plan looks correct, apply the configuration to deploy the infrastructure.

```bash
terraform apply
```

### 6. Accessing the Application

Once the apply is complete, Terraform will output the public IP address of the load balancer. You can navigate to this IP address in your web browser to see the simple "Welcome" page. The load balancer will distribute your requests across the three web server instances.

### 7. SSH Access

The instances are configured to allow SSH access. You can find the public IP address of each instance in the Google Cloud Console. To connect, use the following command:

```bash
ssh -i ~/.ssh/id_rsa ubuntu@<INSTANCE_PUBLIC_IP>
```

## Cleaning Up

To destroy all the resources created by this project, run the following command:

```bash
terraform destroy
```
