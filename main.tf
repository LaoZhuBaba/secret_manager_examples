terraform {
  required_version = ">= 1.12.2"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.0.1, < 8.0.0"
    }
  }
}


# This resource is stored in state.  There is an ephemeral version of this resource
# which avoids state but it is incompatible with the Secret Manager fabric module
resource "random_password" "random_pw1" {
  length  = 32
  special = false
  keepers = {
    version_number = timestamp()
  }
}

locals {
  // This is an OS command that generates a 32 character string of alphanumeric
  // characters.  Should work on both MacOS and Linux.
  random_password_cmd = "LC_CTYPE=C tr -cd '[:alnum:]' < /dev/urandom | head -c 32"
  random_pw1_version  = 1 # Change this value to generate a new version of random_pw1
  example4_version    = 1 # Change this value to generate a new password for example4
  example5_version    = 1 # Change this value to generate a new password for example5
}


resource "null_resource" "create_example4_secret_file" {
  provisioner "local-exec" {
    command = format(
      "%s > %s",
      local.random_password_cmd,
      "example4_secret.txt"
    )

  }
  triggers = {
    go = local.example4_version
  }
}


resource "null_resource" "create_example5_secret_file" {
  provisioner "local-exec" {
    command = format(
      "echo \"Server=myServerAddress; Database=myDataBase; User Id=myUsername; Password=`%s`\" > %s",
      local.random_password_cmd,
      "example5_secret.txt"
    )
  }
  triggers = {
    go = local.example5_version
  }
}

module "secret-manager-blueprint" {
  source = "./module"

  region     = var.region
  project_id = var.project_id
  secrets = {
    // A secret with no version defined.  This is fine.  You can manually add and modify versions without
    // affecting the terraform state
    example1 = {
      global_replica_locations = {
        "australia-southeast1" = null
        "australia-southeast2" = null
      }
      labels = {
        "businessunit"    = "example_value",
        "subbusinessunit" = "example_value"
        "environment"     = "npe"
      }
      version_config = {
        destroy_ttl = "700000s"
      }
      deletion_protection = false
    }
    // A secret with version data defined that WILL be stored in the state file (because
    // data_config.write_only_version is not set)
    example2 = {
      global_replica_locations = {
        "australia-southeast1" = null
        "australia-southeast2" = null
      }
      labels = {
        "businessunit"    = "example_value",
        "subbusinessunit" = "example_value"
        "environment"     = "npe"
      }
      versions = {
        a = {
          data = random_password.random_pw1.result
        }
      }
    }
    // A secret with version data defined that will NOT be stored in the state file.  But 
    // random_password.random_pw1.result IS stored in state!
    example3 = {
      global_replica_locations = {
        "australia-southeast1" = null
        "australia-southeast2" = null
      }
      labels = {
        "businessunit"    = "example_value",
        "subbusinessunit" = "example_value"
        "environment"     = "npe"
      }
      versions = {
        a = {
          data = random_password.random_pw1.result
          data_config = {
            write_only_version = local.random_pw1_version
          }
        }
      }
    }

    // A secret version pulled from a file so no sensitive data stored in state
    example4 = {
      global_replica_locations = {
        "australia-southeast2" = null
      }
      labels = {
        "businessunit"    = "example_value",
        "subbusinessunit" = "example_value"
        "environment"     = "npe"
      }
      versions = {
        a = {
          data = "./example4_secret.txt"
          data_config = {
            write_only_version = local.example4_version
            is_file            = true
          }
        }
      }
    }

    // A secret version pulled from a file containing a SQL connection string.
    // No sensitive data stored in state
    example5 = {
      global_replica_locations = {
        "australia-southeast1" = null
      }
      labels = {
        "businessunit"    = "example_value",
        "subbusinessunit" = "example_value"
        "environment"     = "npe"
      }
      versions = {
        a = {
          data = "./example5_secret.txt"
          data_config = {
            write_only_version = local.example5_version
            is_file            = true
          }
        }
      }
    }

    example_regional = {
      labels = {
        "businessunit"    = "example_value",
        "subbusinessunit" = "example_value",
        "environment"     = "npe"
      }
      location = "australia-southeast1"
      versions = {
        a = {
          data = random_password.random_pw1.result
        }
      }
    }
  }
}

output "out" {
  value     = module.secret-manager-blueprint.out
  sensitive = true
}
