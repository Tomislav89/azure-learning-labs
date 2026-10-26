terraform {
  required_version = ">= 1.5.0"
}

resource "terraform_data" "environment" {
  input = {
    workspace = terraform.workspace
    name      = "lab-${terraform.workspace}"
  }
}

output "current_environment" {
  value = terraform_data.environment.output
}
