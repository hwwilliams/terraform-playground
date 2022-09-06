data "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network.name
  resource_group_name = var.virtual_network.resource_group_name
}

resource "azurerm_subnet" "snet" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = data.azurerm_virtual_network.vnet.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  address_prefixes     = each.value
}

resource "azurerm_application_security_group" "asg" {
  for_each            = var.application_security_groups
  name                = each.key
  resource_group_name = azurerm_resource_group.rg[each.value].name
  location            = azurerm_resource_group.rg[each.value].location
}

resource "azurerm_network_security_group" "nsg" {
  for_each            = var.network_security_groups
  name                = each.key
  resource_group_name = azurerm_resource_group.rg[each.value.resource_group_name].name
  location            = azurerm_resource_group.rg[each.value.resource_group_name].location

  dynamic "security_rule" {
    for_each = each.value.security_rules
    content {
      name                                       = security_rule.key
      priority                                   = ((((index(keys(each.value.security_rules), security_rule.key) + 1)) * 5) + 100)
      direction                                  = security_rule.value.direction
      access                                     = security_rule.value.access
      protocol                                   = security_rule.value.protocol
      destination_address_prefix                 = security_rule.value.destination_address_prefix
      destination_address_prefixes               = security_rule.value.destination_address_prefixes
      destination_application_security_group_ids = security_rule.value.destination_address_prefix == null && security_rule.value.destination_address_prefixes == null ? flatten([for asg_name in security_rule.value.destination_application_security_groups : azurerm_application_security_group.asg[asg_name].id]) : null
      destination_port_range                     = security_rule.value.destination_port_range
      destination_port_ranges                    = security_rule.value.destination_port_ranges
      source_address_prefix                      = security_rule.value.source_address_prefix
      source_address_prefixes                    = security_rule.value.source_address_prefixes
      source_application_security_group_ids      = security_rule.value.source_address_prefix == null && security_rule.value.source_address_prefixes == null ? flatten([for asg_name in security_rule.value.source_application_security_groups : azurerm_application_security_group.asg[asg_name].id]) : null
      source_port_range                          = security_rule.value.source_port_range
      source_port_ranges                         = security_rule.value.source_port_ranges
    }
  }
}

locals {
  nsg_subnet_associations = flatten([
    for nsg_name, nsg_property in var.network_security_groups : [
      for subnet_name in nsg_property.associated_subnets : {
        nsg_name    = nsg_name
        subnet_name = subnet_name
      }
    ]
  ])
}

resource "azurerm_subnet_network_security_group_association" "snet_nsg" {
  for_each = {
    for association in local.nsg_subnet_associations :
    "${association.subnet_name}/${association.nsg_name}" => association
  }

  subnet_id                 = azurerm_subnet.snet[each.value.subnet_name].id
  network_security_group_id = azurerm_network_security_group.nsg[each.value.nsg_name].id
}
