terraform {
  required_version = ">= 1.12.2"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.0.1, < 8.0.0"
    }
  }
}

module "secret-manager" {
  source     = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git//modules/secret-manager"
  project_id = var.project_id

  secrets = var.secrets
}

output "out" {
  value     = var.secrets
  sensitive = true
}
