variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "secrets" {
  type = map(object({
    # annotations = optional(map(string), {})
    deletion_protection = optional(bool, false) // TODO put default back to true
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
    version_config = optional(object({
      aliases     = optional(map(number))
      destroy_ttl = optional(string, "604800s") // 7 days
    }), {})
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
      for k in var.secrets :
      timecmp(timeadd(plantimestamp(), k.version_config.destroy_ttl), timeadd(plantimestamp(), "167h59m59s")) == 1
    ])
    error_message = "destroy_ttl must be at least 7 days"
  }
  validation {
    condition = alltrue([
      for k in var.secrets :
      k.deletion_protection == false # TODO reverse this.  false is needed for testing
    ])
    error_message = "deletion_protection must be set to true"
  }
  validation {
    condition = alltrue([
      for k, v in var.secrets :
      # The first try() checks if v.location is null or an empty string
      # The second try() checks if  v.global_replica_locatsions is null or zero length
      # What we need is for exactly one of these conditions to be true.
      try(coalesce(v.location), false) != false || try(length(v.global_replica_locations), 0) != 0
    ])
    error_message = "global_replica_locations & location cannot both be empty or null"
  }
  validation {
    condition = alltrue([
      # Using "never_match" as a default value ensures that the test fails if the "environment" key is missing
      for k, v in var.secrets : contains(local.valid_environments, lookup(v.labels, "environment", "never_match"))
    ])
    error_message = "ARPC-004"
  }
  validation {
    condition = alltrue(flatten([
      for k, v in var.secrets : [
        # It is okay for global_replica_locations to be null, in which case the for
        # loop terminates immediately.  But if global_replica_locations is not null
        # then each of its element must match an element in local.australian_regions.
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
      # This try() returns true if v.location is not null and not empty
      try(coalesce(v.location), false) != false ? contains(local.australian_regions, v.location) : true
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
    error_message = format(
      "%s %s validation: Missing label.  Must include all of: %v",
      local.message_prefix,
      local.module_name,
      local.required_labels
    )
  }
}
