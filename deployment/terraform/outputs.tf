output "resource_group_name" {
  description = "OrderFlow production resource group."
  value       = azurerm_resource_group.orderflow.name
}

output "aks_cluster_name" {
  description = "Private AKS cluster name."
  value       = azurerm_kubernetes_cluster.orderflow.name
}

output "acr_name" {
  description = "ACR registry name used by the release workflow."
  value       = azurerm_container_registry.orderflow.name
}

output "acr_login_server" {
  description = "ACR login server; no registry password is output."
  value       = azurerm_container_registry.orderflow.login_server
}
