terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "orderflow" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_container_registry" "orderflow" {
  name                          = var.acr_name
  resource_group_name           = azurerm_resource_group.orderflow.name
  location                      = azurerm_resource_group.orderflow.location
  sku                           = "Standard"
  admin_enabled                 = false
  public_network_access_enabled = true
  tags                          = local.common_tags
}

resource "azurerm_kubernetes_cluster" "orderflow" {
  name                              = var.aks_cluster_name
  location                          = azurerm_resource_group.orderflow.location
  resource_group_name               = azurerm_resource_group.orderflow.name
  dns_prefix                        = "${var.aks_cluster_name}-dns"
  private_cluster_enabled           = true
  local_account_disabled            = true
  role_based_access_control_enabled = true
  azure_policy_enabled              = true
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  tags                              = local.common_tags

  default_node_pool {
    name                         = "system"
    vm_size                      = var.node_vm_size
    auto_scaling_enabled         = true
    min_count                    = var.node_min_count
    max_count                    = var.node_max_count
    os_sku                       = "AzureLinux"
    only_critical_addons_enabled = true
    upgrade_settings {
      max_surge = "33%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "azure"
    load_balancer_sku   = "standard"
  }

  depends_on = [azurerm_container_registry.orderflow]
}

resource "azurerm_role_assignment" "aks_pull_acr" {
  scope                = azurerm_container_registry.orderflow.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.orderflow.kubelet_identity[0].object_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "github_deploy_aks" {
  count                = var.github_deploy_identity_object_id == null ? 0 : 1
  scope                = "${azurerm_kubernetes_cluster.orderflow.id}/namespaces/orderflow-production"
  role_definition_name = "Azure Kubernetes Service RBAC Writer"
  principal_id         = var.github_deploy_identity_object_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "github_push_acr" {
  count                = var.github_deploy_identity_object_id == null ? 0 : 1
  scope                = azurerm_container_registry.orderflow.id
  role_definition_name = "AcrPush"
  principal_id         = var.github_deploy_identity_object_id
  principal_type       = "ServicePrincipal"
}

locals {
  common_tags = {
    application = "OrderFlow"
    environment = "production"
    release     = "2.3.0"
    managed_by  = "Terraform"
  }
}
