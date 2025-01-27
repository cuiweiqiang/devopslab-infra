resource "azurerm_resource_group" "rg_aks" {
  name     = local.aks_rg_name
  location = var.location
  tags     = var.tags
}


resource "azurerm_resource_group" "rg_aks_backup" {
  name     = local.aks_backup_rg_name
  location = var.location
  tags     = var.tags
}



module "aks" {
  source = "git::https://github.com/pagopa/terraform-azurerm-v3.git//kubernetes_cluster?ref=enable-workload-identity"

  count = var.aks_enabled ? 1 : 0

  name                       = local.aks_cluster_name
  resource_group_name        = azurerm_resource_group.rg_aks.name
  location                   = azurerm_resource_group.rg_aks.location
  dns_prefix                 = "${local.project}-aks"
  kubernetes_version         = var.aks_kubernetes_version
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.log_analytics_workspace.id
  sku_tier                   = var.aks_sku_tier

  #
  # 🤖 System node pool
  #
  system_node_pool_name = var.aks_system_node_pool.name
  ### vm configuration
  system_node_pool_vm_size         = var.aks_system_node_pool.vm_size
  system_node_pool_os_disk_type    = var.aks_system_node_pool.os_disk_type
  system_node_pool_os_disk_size_gb = var.aks_system_node_pool.os_disk_size_gb
  system_node_pool_node_count_min  = var.aks_system_node_pool.node_count_min
  system_node_pool_node_count_max  = var.aks_system_node_pool.node_count_max
  ### K8s node configuration
  system_node_pool_node_labels = var.aks_system_node_pool.node_labels
  system_node_pool_tags        = var.aks_system_node_pool.node_tags

  #
  # 👤 User node pool
  #
  user_node_pool_enabled = var.aks_user_node_pool.enabled
  user_node_pool_name    = var.aks_user_node_pool.name
  ### vm configuration
  user_node_pool_vm_size         = var.aks_user_node_pool.vm_size
  user_node_pool_os_disk_type    = var.aks_user_node_pool.os_disk_type
  user_node_pool_os_disk_size_gb = var.aks_user_node_pool.os_disk_size_gb
  user_node_pool_node_count_min  = var.aks_user_node_pool.node_count_min
  user_node_pool_node_count_max  = var.aks_user_node_pool.node_count_max
  ### K8s node configuration
  user_node_pool_node_labels = var.aks_user_node_pool.node_labels
  user_node_pool_node_taints = var.aks_user_node_pool.node_taints
  user_node_pool_tags        = var.aks_user_node_pool.node_tags
  # end user node pool

  #
  # ☁️ Network
  #
  vnet_id        = data.azurerm_virtual_network.vnet_aks.id
  vnet_subnet_id = module.snet_aks.id

  outbound_ip_address_ids = [data.azurerm_public_ip.pip_aks_outboud.id]
  private_cluster_enabled = var.aks_private_cluster_enabled
  network_profile = {
    docker_bridge_cidr = "172.17.0.1/16"
    dns_service_ip     = "10.250.0.10"
    network_plugin     = "azure"
    network_policy     = "azure"
    outbound_type      = "loadBalancer"
    service_cidr       = "10.250.0.0/16"
  }
  # end network
  oidc_issuer_enabled = true

  aad_admin_group_ids = var.env_short == "d" ? [data.azuread_group.adgroup_admin.object_id, data.azuread_group.adgroup_developers.object_id, data.azuread_group.adgroup_externals.object_id] : [data.azuread_group.adgroup_admin.object_id]

  addon_azure_policy_enabled                     = var.aks_addons.azure_policy
  addon_azure_key_vault_secrets_provider_enabled = var.aks_addons.azure_key_vault_secrets_provider
  addon_azure_pod_identity_enabled               = var.aks_addons.pod_identity_enabled

  default_metric_alerts = var.aks_metric_alerts_default
  custom_metric_alerts  = var.aks_metric_alerts_custom

  alerts_enabled = var.aks_alerts_enabled
  action = [
    {
      action_group_id    = data.azurerm_monitor_action_group.slack.id
      webhook_properties = null
    },
    {
      action_group_id    = data.azurerm_monitor_action_group.email.id
      webhook_properties = null
    }
  ]

  tags = var.tags

  depends_on = [
    module.snet_aks,
    data.azurerm_public_ip.pip_aks_outboud,
    data.azurerm_virtual_network.vnet_aks
  ]
}

resource "azurerm_kubernetes_cluster_node_pool" "spot_node_pool" {
  count = var.aks_spot_user_node_pool.enabled ? 1 : 0

  kubernetes_cluster_id = module.aks[0].id

  name = var.aks_spot_user_node_pool.name

  ### vm configuration
  vm_size = var.aks_spot_user_node_pool.vm_size
  # https://docs.microsoft.com/en-us/azure/virtual-machines/sizes-general
  os_disk_type           = var.aks_spot_user_node_pool.os_disk_type # Managed or Ephemeral
  os_disk_size_gb        = var.aks_spot_user_node_pool.os_disk_size_gb
  zones                  = ["1", "2", "3"]
  ultra_ssd_enabled      = false
  enable_host_encryption = false
  os_type                = "Linux"
  priority               = "Spot"
  eviction_policy        = "Delete"

  ### autoscaling
  enable_auto_scaling = true
  node_count          = var.aks_spot_user_node_pool.node_count_min
  min_count           = var.aks_spot_user_node_pool.node_count_min
  max_count           = var.aks_spot_user_node_pool.node_count_max

  ### K8s node configuration
  max_pods    = 250
  node_labels = var.aks_spot_user_node_pool.node_labels
  node_taints = var.aks_spot_user_node_pool.node_taints

  ### networking
  vnet_subnet_id        = module.snet_aks.id
  enable_node_public_ip = false

  tags = merge(var.tags, var.aks_spot_user_node_pool.node_tags)

  lifecycle {
    ignore_changes = [
      node_count
    ]
  }
}


# resource "azurerm_role_assignment" "managed_identity_operator_vs_aks_managed_identity" {
#   scope                = azurerm_resource_group.rg_aks.id
#   role_definition_name = "Managed Identity Operator"
#   principal_id         = module.aks[0].identity_principal_id
# }

#
# ACR connection
#
# add the role to the identity the kubernetes cluster was assigned
resource "azurerm_role_assignment" "aks_to_acr" {
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = module.aks[0].kubelet_identity_id

  depends_on = [module.aks]
}

#
# Vnet Link
#

# vnet needs a vnet link with aks private dns zone
# aks terrform module doesn't export private dns zone
resource "null_resource" "create_vnet_core_aks_link" {

  count = var.aks_enabled && var.aks_private_cluster_enabled ? 1 : 0
  triggers = {
    cluster_name = module.aks[0].name
    vnet_id      = data.azurerm_virtual_network.vnet_core.id
    vnet_name    = data.azurerm_virtual_network.vnet_core.name
  }

  provisioner "local-exec" {
    command = <<EOT
      dns_zone_name=$(az network private-dns zone list --output tsv --query "[?contains(id,'${self.triggers.cluster_name}')].{name:name}")
      dns_zone_resource_group_name=$(az network private-dns zone list --output tsv --query "[?contains(id,'${self.triggers.cluster_name}')].{resourceGroup:resourceGroup}")
      az network private-dns link vnet create \
        --name ${self.triggers.vnet_name} \
        --registration-enabled false \
        --resource-group $dns_zone_resource_group_name \
        --virtual-network ${self.triggers.vnet_id} \
        --zone-name $dns_zone_name
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      dns_zone_name=$(az network private-dns zone list --output tsv --query "[?contains(id,'${self.triggers.cluster_name}')].{name:name}")
      dns_zone_resource_group_name=$(az network private-dns zone list --output tsv --query "[?contains(id,'${self.triggers.cluster_name}')].{resourceGroup:resourceGroup}")
      az network private-dns link vnet delete \
        --name ${self.triggers.vnet_name} \
        --resource-group $dns_zone_resource_group_name \
        --zone-name $dns_zone_name \
        --yes
    EOT
  }

  depends_on = [
    module.aks
  ]
}

module "velero" {
  source                              = "git::https://github.com/pagopa/terraform-azurerm-v3.git//kubernetes_cluster_velero?ref=v7.52.0"
  count                               = var.aks_enabled ? 1 : 0
  backup_storage_container_name       = "velero-backup"
  subscription_id                     = data.azurerm_subscription.current.subscription_id
  tenant_id                           = data.azurerm_subscription.current.tenant_id
  resource_group_name                 = azurerm_resource_group.rg_aks_backup.name
  prefix                              = "devopla"
  aks_cluster_name                    = module.aks[count.index].name
  aks_cluster_rg                      = azurerm_resource_group.rg_aks.name
  location                            = var.location
  use_storage_private_endpoint        = true
  private_endpoint_subnet_id          = data.azurerm_subnet.private_endpoint_subnet.id
  storage_account_private_dns_zone_id = data.azurerm_private_dns_zone.storage_account_private_dns_zone.id

  tags = var.tags
}

module "aks_namespace_backup" {
  source = "git::https://github.com/pagopa/terraform-azurerm-v3.git//kubernetes_velero_backup?ref=v7.52.0"
  count  = var.aks_enabled ? 1 : 0
  # required
  backup_name      = "daily-backup"
  namespaces       = ["ALL"]
  aks_cluster_name = module.aks[count.index].name

  # optional
  ttl             = "72h0m0s"
  schedule        = "0 3 * * *" #refers to UTC timezone
  volume_snapshot = false

  depends_on = [
    module.velero
  ]
}
