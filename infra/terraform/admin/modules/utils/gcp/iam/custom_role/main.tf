data "google_project" "current" {}

locals {
  custom_roles = {
    tf_workspace = {
      role_id     = "tfCPWorkspaceProjectRole"
      title       = "Terraform cloud workspace role"
      description = "Terraform cloud workspace role."
      permissions = [
        "resourcemanager.projects.getIamPolicy",
        "resourcemanager.projects.setIamPolicy",
        "storage.buckets.getIamPolicy",
        "storage.buckets.setIamPolicy",
        "secretmanager.secrets.getIamPolicy",
        "secretmanager.secrets.setIamPolicy",
        "compute.subnetworks.getIamPolicy",
        "compute.subnetworks.setIamPolicy"
      ]
    }
  }
}


resource "google_project_iam_custom_role" "custom_roles" {
  for_each = local.custom_roles

  project     = data.google_project.current.project_id
  role_id     = each.value.role_id
  title       = each.value.title
  description = each.value.description
  permissions = each.value.permissions
}


output "created_roles" {
  value = {
    for custom_role, custom_role_obj in google_project_iam_custom_role.custom_roles :
    custom_role => {
      id   = custom_role_obj.id
      name = custom_role_obj.name
    }
  }
  sensitive   = false
  description = "Custom roles name and ID."
  depends_on  = [google_project_iam_custom_role.custom_roles]
}
