locals {
  connection_string = format(
    "Server=myServerAddress; Database=myDataBase; User Id=myUsername; Password=%s;",
    random_password.random_pw1.result
  )
  version_number = 1
}


resource "random_password" "random_pw1" {
  length = 32
  # Avoid special characters because some may be unsupported.
  special = false
  keepers = {
    version_number = local.version_number
  }
}

resource "null_resource" "create_secret_file" {
  provisioner "local-exec" {
    command = "LC_CTYPE=C tr -cd '[:alnum:]' < /dev/urandom | head -c 32 > secret.txt"
  }
  triggers = {
    go = local.version_number
  }
}

module "secret-manager" {
  source     = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git//modules/secret-manager"
  project_id = var.project_id

  secrets = {
    // A secret with no version defined.  This is fine.  You can manually add and modify versions without
    // affecting the terraform state
    example1 = {
      global_replica_locations = {
        (var.region) = null
      }
    }
    // A secret with version data defined that WILL be stored in the state file (because
    // data_config.write_only_version is not set)
    example2 = {
      global_replica_locations = {
        (var.region) = null
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
        (var.region) = null
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
    // A secret based on a random value and a literal string.  Not stored in state.  But 
    // random_password.random_pw1.result IS stored in state!
    example4 = {
      global_replica_locations = {
        (var.region) = null
      }
      versions = {
        a = {
          //data = format("password: %s", random_password.random_pw1.result)
          data = format("password: %s", random_password.random_pw1.result)
          data_config = {
            write_only_version = local.version_number
          }
        }
      }
    }

    // A secret based on a variable that is composed of a literal string plus a random value.
    // random_password.random_pw1.result IS stored in state!
    example5 = {
      global_replica_locations = {
        (var.region) = null
      }
      versions = {
        a = {
          data = local.connection_string
          data_config = {
            write_only_version = local.version_number
          }
        }
      }
    }

    // A secret version pulled from a file
    // No sensitive data stored in state :-)
    // In this example, the secret.txt file is created by the local-exec provisioner.
    // It could also be auto-generated in a CI pipeline.
    example6 = {
      global_replica_locations = {
        (var.region) = null
      }
      versions = {
        a = {
          data = "./secret.txt"
          data_config = {
            write_only_version = local.version_number
            is_file            = true
          }
        }
      }
    }
  }
}
