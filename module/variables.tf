variable "project_id" {
  type = string
}

variable "region" {
  type = string
}


variable "secrets" {
  type = map(object({
    # annotations = optional(map(string), {})
    # deletion_protection = optional(bool)
    # kms_key             = optional(string)
    labels                   = map(string)
    global_replica_locations = optional(map(string))
    # "australia-southeast1" : null,
    # "australia-southeast2" : null,
    # }
    location = optional(string)
    # tag_bindings = optional(map(string))
    # tags         = optional(map(string), {})
    # expiration_config = optional(object({
    #   time = optional(string)
    #   ttl  = optional(string)
    # }))
    # iam = optional(map(list(string)), {})
    # iam_bindings = optional(map(object({
    #   members = list(string)
    #   role    = string
    #   condition = optional(object({
    #     expression  = string
    #     title       = string
    #     description = optional(string)
    #   }))
    # })), {})
    # iam_bindings_additive = optional(map(object({
    #   member = string
    #   role   = string
    #   condition = optional(object({
    #     expression  = string
    #     title       = string
    #     description = optional(string)
    #   }))
    # })), {})
    # version_config = optional(object({
    #   aliases     = optional(map(number))
    #   destroy_ttl = optional(string)
    # }), {})
    versions = optional(map(object({
      data            = string
      deletion_policy = optional(string)
      enabled         = optional(bool)
      data_config = optional(object({
        is_base64          = optional(bool, false)
        is_file            = optional(bool, false)
        write_only_version = optional(number)
      }))
    })), {})
  }))
  validation {
    condition = alltrue([
      for k, v in var.secrets :
      v.location != null || (v.global_replica_locations != null && length(v.global_replica_locations) > 0)
    ])
    error_message = "global_replica_locations & location cannot both be empty or null"
  }
  validation {
    condition = alltrue(flatten([
      for k, v in var.secrets : [
        for grk, grv in v.global_replica_locations == null ? {} : v.global_replica_locations : contains(
          local.australian_regions, grk
        )
      ]
    ]))
    error_message = format(
      "global_replica_locations must contain values exclusively from the list: %v",
      local.australian_regions
    )
  }
  validation {
    condition = alltrue(flatten([
      for k, v in var.secrets :
      v.location != null ? contains(local.australian_regions, v.location) : true
    ]))
    error_message = format(
      "If location is set for a regional secret it must have a value from the list: %v",
      local.australian_regions
    )
  }
  validation {
    condition = alltrue(flatten([
      for k, v in var.secrets : [
        for lv in local.required_labels : contains(keys(v.labels), lv)
      ]
    ]))
    error_message = format("Missing label.  Must include all of: %v", local.required_labels)
  }
}
