variable "zitadel_admin_username" {
  description = "Zitadel administrator username."
  type        = string
  sensitive   = true
}

variable "zitadel_admin_password" {
  description = "Zitadel administrator password."
  type        = string
  sensitive   = true
}

variable "zitadel_database" {
  description = "The name of the zitadel database."
  type        = string
  sensitive   = true
}

variable "zitadel_database_min_acu" {
  description = "The minimum serverless capacity for the database."
  type        = number
}

variable "zitadel_database_max_acu" {
  description = "The maximum serverless capacity for the database."
  type        = number
}

variable "zitadel_database_username" {
  description = "The zitadel username to use for the database."
  type        = string
  sensitive   = true
}

variable "zitadel_database_password" {
  description = "The zitadel password to use for the database."
  type        = string
  sensitive   = true
}

variable "zitadel_database_admin_username" {
  description = "The cluster's username to use for the database."
  type        = string
  sensitive   = true
}

variable "zitadel_database_admin_password" {
  description = "The cluster's admin password to use for the database."
  type        = string
  sensitive   = true
}

variable "zitadel_secret_key" {
  description = "The secret key to use for the zitadel instance."
  type        = string
  sensitive   = true
}
