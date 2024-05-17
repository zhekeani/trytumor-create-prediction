variable "trytumor_bucket_name" {
  type        = string
  default     = ""
  description = "trytumor project storage bucket name."
}

variable "cloud_fn_zip_path" {
  type        = string
  default     = ""
  description = "The path to the zip file of the cloud function in Storage Bucket."
}


variable "cloud_fn_dir_path" {
  type        = string
  default     = "/home/zhahrany/Zhahrany/Pribadi/Development/NestJs/Projects/07-trytumor/trytumor-create-prediction/app_cloudfn"
  description = "Cloud function source code directory path."
}

variable "archive_output" {
  type = object({
    md5  = string
    path = string
  })
  default = {
    md5  = "7c164c0f1c28fcd4d9e6396d908151b3"
    path = "/home/zhahrany/Zhahrany/Pribadi/Development/NestJs/Projects/07-trytumor/trytumor-create-prediction/app_cloudfn/tmp/function.zip"
  }
  description = "Archive output."
}
