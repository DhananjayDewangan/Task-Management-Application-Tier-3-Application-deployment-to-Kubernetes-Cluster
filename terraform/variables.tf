variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "task_management"
}

variable "db_user" {
  description = "PostgreSQL username"
  type        = string
  default     = "taskuser"
}

variable "db_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}

variable "image_tag" {
  description = "Docker image tag for application containers"
  type        = string
  default     = "1.0"
}