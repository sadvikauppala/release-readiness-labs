variable "resource_group_name" {
  description = "Azure resource group for the OrderFlow production platform."
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID for the production platform."
  type        = string
}

variable "location" {
  description = "Azure region selected by the production architecture review."
  type        = string
}

variable "aks_cluster_name" {
  description = "Globally unique AKS cluster name."
  type        = string
}

variable "acr_name" {
  description = "Globally unique Azure Container Registry name (5-50 alphanumeric characters)."
  type        = string

  validation {
    condition     = length(var.acr_name) >= 5 && length(var.acr_name) <= 50 && can(regex("^[a-z0-9]+$", var.acr_name))
    error_message = "acr_name must be 5-50 characters and contain only lowercase letters and digits."
  }
}

variable "github_deploy_identity_object_id" {
  description = "Optional object ID of the GitHub Actions federated identity. Set after bootstrapping the cluster and production namespace; no client secret is used."
  type        = string
  default     = null
  nullable    = true
}

variable "node_vm_size" {
  description = "Approved AKS system node VM size."
  type        = string
  default     = "Standard_D2s_v5"
}

variable "node_min_count" {
  description = "Minimum production node count."
  type        = number
  default     = 3

  validation {
    condition     = var.node_min_count >= 3
    error_message = "Production AKS must retain at least three nodes for availability."
  }
}

variable "node_max_count" {
  description = "Maximum autoscaled production node count."
  type        = number
  default     = 5

  validation {
    condition     = var.node_max_count >= var.node_min_count
    error_message = "node_max_count must be greater than or equal to node_min_count."
  }
}
