data "azurerm_resource_group" "resource_group" {
  name = "${local.project}-azdoa-rg"
}


module "azdoa_custom_image" {
  source              = "git::https://github.com/pagopa/terraform-azurerm-v3.git//azure_devops_agent_custom_image?ref=v7.8.0"
  resource_group_name = data.azurerm_resource_group.resource_group.name
  location            = var.location
  image_name          = "azdo-agent-ubuntu2204-image-velero"
  image_version       = "v2"
  subscription_id     = data.azurerm_subscription.current.subscription_id
  prefix              = "devopla"
  tags                = var.tags
}
