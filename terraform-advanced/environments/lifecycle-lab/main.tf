terraform {
  required_version = ">= 1.5.0"
}

resource "terraform_data" "network" {
  input = "network-version-3"
}

resource "terraform_data" "application" {
  input = "application-ready"

  depends_on = [
    terraform_data.network
  ]

  lifecycle {
    replace_triggered_by = [
      terraform_data.network
    ]
  }
}

output "application_status" {
  value = terraform_data.application.output
}
