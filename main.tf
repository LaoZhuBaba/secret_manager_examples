resource "random_password" "random_pw1" {
  length = 32
  # Avoid special characters because some may be unsupported.
  special = false
  keepers = {
    version_number = local.version_number
  }
}

locals {
  connection_string = format(
    "Server=myServerAddress; Database=myDataBase; User Id=myUsername; Password=%s;",
    random_password.random_pw1.result
  )
  version_number = 1
}


module "secret-manager-blueprint" {
  source = "./module"

  region     = var.region
  project_id = var.project_id
  secrets = {
    #     // A secret with no version defined.  This is fine.  You can manually add and modify versions without
    #     // affecting the terraform state
    #     example1 = {
    #       global_replica_locations = {
    #         (var.region) = null
    #       }
    #     }
    #     // A secret with version data defined that WILL be stored in the state file (because
    #     // data_config.write_only_version is not set)
    #     example2 = {
    #       global_replica_locations = {
    #         (var.region) = null
    #       }
    #       versions = {
    #         a = {
    #           data = random_password.random_pw1.result
    #         }
    #       }
    #     }
    // A secret with version data defined that will NOT be stored in the state file.  But 
    // random_password.random_pw1.result IS stored in state!
    example3 = {
      global_replica_locations = {
        "australia-southeast1" = null
        "australia-southeast2" = null
      }
      labels = {
        "businessunit"    = "jkjkj",
        "subbusinessunit" = "jkjkj"
      }
      versions = {
        a = {
          data = random_password.random_pw1.result
          data_config = {
            write_only_version = local.version_number
          }
        }
      }
    }
    #     // A secret based on a random value and a literal string.  Not stored in state.  But 
    #     // random_password.random_pw1.result IS stored in state!
    #     example4 = {
    #       global_replica_locations = {
    #         (var.region) = null
    #       }
    #       versions = {
    #         a = {
    #           //data = format("password: %s", random_password.random_pw1.result)
    #           data = format("password: %s", random_password.random_pw1.result)
    #           data_config = {
    #             write_only_version = local.version_number
    #           }
    #         }
    #       }
    #     }

    #     // A secret based on a variable that is composed of a literal string plus a random value.
    #     // random_password.random_pw1.result IS stored in state!
    #     example5 = {
    #       global_replica_locations = {
    #         (var.region) = null
    #       }
    #       versions = {
    #         a = {
    #           data = local.connection_string
    #           data_config = {
    #             write_only_version = local.version_number
    #           }
    #         }
    #       }
    #     }

    #     // A secret version pulled from a file
    #     // No sensitive data stored in state :-)
    #     // I'm assuming that in the real world, ./secret.txt would be auto-generated
    #     // in a CI pipeline and never written to a repo.
    #     example6 = {
    #       global_replica_locations = {
    #         (var.region) = null
    #       }
    #       versions = {
    #         a = {
    #           data = "./secret.txt"
    #           data_config = {
    #             write_only_version = local.version_number
    #             is_file            = true
    #           }
    #         }
    #       }
    #     }
    example7 = {
      labels = {
        "businessunit"    = "jkjkj",
        "subbusinessunit" = "jkjkj"
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
