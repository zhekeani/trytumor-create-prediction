terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "zhekeani-first-org"

    workspaces {
      name = "trytumor-cp-admin"
    }
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.23.0"
    }

  }
}