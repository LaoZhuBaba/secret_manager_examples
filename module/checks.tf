check "match_parent_env" {
  data "google_project" "project" {
    project_id = var.project_id
  }
  assert {
    condition = alltrue([
      # Using "never_match" as a default value ensures that the test fails if the "environment" key is missing
      for k, v in var.secrets : lookup(v.labels, "environment", "never_match") == lookup(data.google_project.project.labels, "environment", "")
    ])
    error_message = "The 'environment' labels on the secret and the parent project do not match"
  }
}
