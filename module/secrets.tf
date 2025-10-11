module "secret-manager" {
  source     = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git//modules/secret-manager"
  project_id = var.project_id

  secrets = var.secrets
}

output "out" {
  value     = var.secrets
  sensitive = true
}
