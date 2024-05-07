data "google_project" "current" {}

locals {
  tf_org_name  = "zhekeani-first-org"
  project_name = "${data.google_project.current.name}-cp"
}

module "custom_role" {
  source = "./modules/utils/gcp/iam/custom_role"
}

module "service_account" {
  source       = "./modules/utils/gcp/service-account"
  project_name = local.project_name

  depends_on = [module.custom_role]
}


module "tf_workspaces" {
  source       = "./modules/environments/terraform-workspaces"
  project_name = local.project_name
  tf_org_name  = local.tf_org_name
  tf_service_accounts = {
    tf_development = module.service_account.all["tf_development"]
  }

  depends_on = [module.custom_role, module.service_account]
}
