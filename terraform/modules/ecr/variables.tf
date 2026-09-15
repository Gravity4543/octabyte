variable "project_name" {
  description = "Project name used for the repository name."
  type        = string
}

variable "max_image_count" {
  description = "How many tagged images to keep before expiring the oldest."
  type        = number
  default     = 10
}

variable "untagged_expiry_days" {
  description = "Expire untagged images after this many days."
  type        = number
  default     = 3
}
