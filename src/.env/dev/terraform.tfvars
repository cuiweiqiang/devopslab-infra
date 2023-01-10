# general
env_short      = "d"
env            = "lab"
prefix         = "dvopla"
domain         = "core"
location       = "northeurope"
location_short = "neu"

tags = {
  CreatedBy   = "Terraform"
  Environment = "Lab"
  Owner       = "DevOps"
  Source      = "https://github.com/pagopa/devopslab-infra"
  CostCenter  = "TS310 - PAGAMENTI & SERVIZI"
}

lock_enable = false

# 🔐 key vault
key_vault_name    = "dvopla-d-neu-kv"
key_vault_rg_name = "dvopla-d-sec-rg"

# ☁️ networking
cidr_vnet                     = ["10.1.0.0/16"]
cidr_subnet_k8s               = ["10.1.0.0/17"]
cidr_subnet_appgateway        = ["10.1.128.0/24"]
cidr_subnet_postgres          = ["10.1.129.0/24"]
cidr_subnet_azdoa             = ["10.1.130.0/24"]
cidr_subnet_app_docker        = ["10.1.132.0/24"]
cidr_subnet_flex_dbms         = ["10.1.133.0/24"]
cidr_subnet_apim              = ["10.1.136.0/24"]
cidr_subnet_appgateway_beta   = ["10.1.138.0/24"]
cidr_subnet_vpn               = ["10.1.139.0/24"]
cidr_subnet_dnsforwarder      = ["10.1.140.0/29"]
cidr_subnet_private_endpoints = ["10.1.141.0/24"]
cidr_subnet_eventhub          = ["10.1.142.0/24"]
cidr_subnet_redis             = ["10.1.143.0/24"]

# dns
prod_dns_zone_prefix = "devopslab"
lab_dns_zone_prefix  = "lab.devopslab"
external_domain      = "pagopa.it"

# azure devops
enable_azdoa        = true
enable_iac_pipeline = true

# VPN
vpn_enabled           = true
dns_forwarder_enabled = true

# app_gateway
app_gateway_is_enabled            = false
app_gateway_sku_name              = "Standard_v2"
app_gateway_sku_tier              = "Standard_v2"
app_gateway_alerts_enabled        = false
app_gateway_waf_enabled           = false
app_gateway_api_certificate_name  = "api-devopslab-pagopa-it"
app_gateway_beta_certificate_name = "beta-devopslab-pagopa-it"
app_gw_beta_is_enabled            = false

#
# 🗺 APIM
#
apim_publisher_name                = "PagoPA DevOpsLab LAB"
apim_sku                           = "Developer_1"
apim_api_internal_certificate_name = "api-internal-devopslab-pagopa-it"

#
# ⛴ AKS
#
aks_networks = [
  {
    domain_name = "dev01"
    vnet_cidr   = ["10.11.0.0/16"]
  },
  {
    domain_name = "dev02"
    vnet_cidr   = ["10.12.0.0/16"]
  }
]

#
# Web app docker
#
is_web_app_service_docker_enabled = false


# postgres
postgres_private_endpoint_enabled      = false
postgres_public_network_access_enabled = false
postgres_network_rules = {
  ip_rules = [
    "0.0.0.0/0"
  ]
  # dblink
  allow_access_to_azure_services = false
}

#
# Postgres Flexible
#
pgflex_private_config = {
  enabled    = false
  sku_name   = "GP_Standard_D2ds_v4"
  db_version = "13"
  # Possible values are 32768, 65536, 131072, 262144, 524288, 1048576,
  # 2097152, 4194304, 8388608, 16777216, and 33554432.
  storage_mb                   = 32768
  zone                         = 1
  backup_retention_days        = 7
  geo_redundant_backup_enabled = true
  private_endpoint_enabled     = true
  pgbouncer_enabled            = true
}

pgflex_private_ha_config = {
  high_availability_enabled = true
  standby_availability_zone = 3
}

pgflex_public_config = {
  enabled    = true
  sku_name   = "B_Standard_B1ms"
  db_version = "13"
  # Possible values are 32768, 65536, 131072, 262144, 524288, 1048576,
  # 2097152, 4194304, 8388608, 16777216, and 33554432.
  storage_mb                   = 32768
  zone                         = 1
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  private_endpoint_enabled     = false
  pgbouncer_enabled            = false
}

pgflex_public_ha_config = {
  high_availability_enabled = false
  standby_availability_zone = 3
}


#
# Event hub
#
ehns_sku_name = "Standard"
eventhubs = [
  {
    name              = "rtd-trx"
    partitions        = 1
    message_retention = 1
    consumers         = ["bpd-payment-instrument", "rtd-trx-fa-comsumer-group", "idpay-consumer-group"]
    keys = [
      {
        name   = "rtd-csv-connector"
        listen = false
        send   = true
        manage = false
      },
      {
        name   = "bpd-payment-instrument"
        listen = true
        send   = false
        manage = false
      },
      {
        name   = "rtd-trx-consumer"
        listen = true
        send   = false
        manage = false
      },
      {
        name   = "rtd-trx-producer"
        listen = false
        send   = true
        manage = false
      }
    ]
  }
]

#
# Redis
#
redis_enabled = true
