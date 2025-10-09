resource "google_project_service" "secret_manager_api" {
  project = local.project_id
  service = "secretmanager.googleapis.com"

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_on_destroy = false
}
