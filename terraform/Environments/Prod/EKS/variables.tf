variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
  default     = "prod-eks"
}

variable "cluster_version" {
  description = "The version of the EKS cluster"
  type        = string
  default     = "1.30"
}
