data "google_project" "current" {}

# Enable the used APIs
module "project-services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 14.5"

  project_id                  = data.google_project.current.project_id
  enable_apis                 = true
  disable_services_on_destroy = false

  activate_apis = [
    "iamcredentials.googleapis.com",
    "iam.googleapis.com"
  ]
}


locals {
  workspaces = {
    development = {
      environment = {
        prefix = "dev"
        type   = "development"
      }
      workspace_id    = "ws-PRV2TtBDtHhL4HiD"
      service_account = var.tf_service_accounts["tf_development"]
      sa_roles = [
        "projects/trytumor/roles/tfCPWorkspaceProjectRole",
        "roles/serviceusage.serviceUsageAdmin",
        "roles/iam.serviceAccountAdmin",
        "roles/iam.serviceAccountKeyAdmin",
        "roles/iam.serviceAccountUser",
        "roles/artifactregistry.admin",
        "roles/iam.workloadIdentityPoolAdmin",
        "roles/secretmanager.admin",
        "roles/run.admin"
      ]
    }
  }
}


module "project_iam_binding" {
  for_each = local.workspaces

  source     = "../../utils/gcp/iam/project-binding"
  sa_email   = each.value.service_account.email
  project_id = data.google_project.current.project_id
  roles      = each.value.sa_roles

  depends_on = [data.google_project.current]
}

module "wif" {
  for_each = local.workspaces

  source       = "../../utils/gcp/iam/tf-wif"
  tf_org_name  = var.tf_org_name
  sa_name      = each.value.service_account.name
  environment  = each.value.environment
  workspace_id = each.value.workspace_id
  project_name = var.project_name
}

output "wif" {
  value = {
    for workspace, workspace_obj in local.workspaces :
    workspace => {
      wip_provider_name = module.wif["${workspace_obj.environment.type}"].wip_provider_name
      wip_sa_email      = workspace_obj.service_account.email
    }
  }
  sensitive   = false
  description = "Workload identity pool provider name and service account email used by Terraform workspaces to authenticate with GCP via Workload Identity Federation."
  depends_on  = [module.wif]
}
