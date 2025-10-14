locals {
  australian_regions = ["australia-southeast1", "australia-southeast2"]
  required_labels    = ["businessunit", "subbusinessunit"]
  valid_environments = ["prod", "npe", "dev"]
  message_prefix     = "AP Blueprint module"
  module_name        = "Secret Manager"
}

