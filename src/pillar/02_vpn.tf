## VPN subnet
module "vpn_snet" {
  source                                         = "git::https://github.com/pagopa/azurerm.git//subnet?ref=version-unlocked"
  name                                           = "GatewaySubnet"
  address_prefixes                               = var.cidr_subnet_vpn
  virtual_network_name                           = module.vnet.name
  resource_group_name                            = azurerm_resource_group.rg_vnet.name
  service_endpoints                              = []
  enforce_private_link_endpoint_network_policies = true
}

data "azuread_application" "vpn_app" {
  display_name = format("%s-app-vpn", local.project)
}

module "vpn" {
  source = "git::https://github.com/pagopa/azurerm.git//vpn_gateway?ref=version-unlocked"

  name                = format("%s-vpn", local.project)
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_vnet.name
  sku                 = var.vpn_sku
  pip_sku             = var.vpn_pip_sku
  subnet_id           = module.vpn_snet.id

  # TODO uncomment when security team will allow this project
  #log_analytics_workspace_id = var.env_short == "p" ? data.azurerm_key_vault_secret.sec_workspace_id[0].value : null
  #log_storage_account_id     = var.env_short == "p" ? data.azurerm_key_vault_secret.sec_storage_id[0].value : null

  vpn_client_configuration = [
    {
      address_space         = ["172.16.1.0/24"],
      vpn_client_protocols  = ["OpenVPN"],
      aad_audience          = data.azuread_application.vpn_app.application_id
      aad_issuer            = format("https://sts.windows.net/%s/", data.azurerm_subscription.current.tenant_id)
      aad_tenant            = format("https://login.microsoftonline.com/%s", data.azurerm_subscription.current.tenant_id)
      radius_server_address = null
      radius_server_secret  = null
      revoked_certificate   = []
      root_certificate      = []
    }
  ]

  tags = var.tags
}

#
# DNS Forwarder
#
resource "azurerm_resource_group" "dns_forwarder" {

  count = var.dns_forwarder_enabled ? 1 : 0

  name     = "${local.project}-dns-forwarder-rg"
  location = var.location

  tags = var.tags
}

module "dns_forwarder_snet" {
  count = var.dns_forwarder_enabled ? 1 : 0

  source                                         = "git::https://github.com/pagopa/azurerm.git//subnet?ref=version-unlocked"
  name                                           = "${local.project}-dnsforwarder-snet"
  address_prefixes                               = var.cidr_subnet_dnsforwarder
  resource_group_name                            = azurerm_resource_group.rg_vnet.name
  virtual_network_name                           = module.vnet.name
  enforce_private_link_endpoint_network_policies = true

  delegation = {
    name = "delegation"
    service_delegation = {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

module "dns_forwarder" {
  source = "git::https://github.com/pagopa/azurerm.git//dns_forwarder?ref=version-unlocked"

  name                = "${local.project}-dns-forwarder"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_vnet.name
  subnet_id           = module.dns_forwarder_snet[0].id

  tags = var.tags
}
