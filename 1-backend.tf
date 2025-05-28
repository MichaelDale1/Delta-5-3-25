# https://www.terraform.io/language/settings/backends/gcs
terraform {
  backend "gcs" {
    bucket      = "tfstate-5-3-25"
    prefix      = "terraform/state"
    credentials = "gcpworldboss3-11-25-12ccb4a9a9a6.json"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}
