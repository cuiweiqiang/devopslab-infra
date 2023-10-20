# resource "azurerm_dns_zone" "public" {
#   count               = (var.dns_zone_prefix == null || var.external_domain == null) ? 0 : 1
#   name                = join(".", [var.dns_zone_prefix, var.external_domain])
#   resource_group_name = azurerm_resource_group.rg_vnet.name

#   tags = var.tags
# }

# # Prod ONLY record to DEV public DNS delegation
# resource "azurerm_dns_ns_record" "dev_pcizone_pagopa_it_ns" {
#   count               = var.env_short == "p" ? 1 : 0
#   name                = "dev"
#   zone_name           = azurerm_dns_zone.public[0].name
#   resource_group_name = azurerm_resource_group.rg_vnet.name
#   records = [
#     "ns1-03.azure-dns.com.",
#     "ns2-03.azure-dns.net.",
#     "ns3-03.azure-dns.org.",
#     "ns4-03.azure-dns.info.",
#   ]
#   ttl  = var.dns_default_ttl_sec
#   tags = var.tags
# }

# resource "azurerm_dns_ns_record" "uat_pcizone_pagopa_it_ns" {
#   count               = var.env_short == "p" ? 1 : 0
#   name                = "uat"
#   zone_name           = azurerm_dns_zone.public[0].name
#   resource_group_name = azurerm_resource_group.rg_vnet.name
#   records = [
#     "ns1-33.azure-dns.com.",
#     "ns2-33.azure-dns.net.",
#     "ns3-33.azure-dns.org.",
#     "ns4-33.azure-dns.info.",
#   ]
#   ttl  = var.dns_default_ttl_sec
#   tags = var.tags
# }

# # application gateway records
# resource "azurerm_dns_a_record" "dns_a_api" {
#   name                = "api"
#   zone_name           = azurerm_dns_zone.public[0].name
#   resource_group_name = azurerm_resource_group.rg_vnet.name
#   ttl                 = var.dns_default_ttl_sec
#   records             = [azurerm_public_ip.appgateway_public_ip.ip_address]
#   tags                = var.tags
# }

# resource "azurerm_dns_a_record" "dns_a_portal" {
#   name                = "portal"
#   zone_name           = azurerm_dns_zone.public[0].name
#   resource_group_name = azurerm_resource_group.rg_vnet.name
#   ttl                 = var.dns_default_ttl_sec
#   records             = [azurerm_public_ip.appgateway_public_ip.ip_address]
#   tags                = var.tags
# }

# resource "azurerm_dns_a_record" "dns_a_management" {
#   name                = "management"
#   zone_name           = azurerm_dns_zone.public[0].name
#   resource_group_name = azurerm_resource_group.rg_vnet.name
#   ttl                 = var.dns_default_ttl_sec
#   records             = [azurerm_public_ip.appgateway_public_ip.ip_address]
#   tags                = var.tags
# }