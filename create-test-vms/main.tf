data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  for_each = var.resource_groups
  name     = each.key
  location = each.value
}

data "azurerm_image" "img" {
  for_each            = var.virtual_machine_image_source
  name                = each.value.name
  resource_group_name = each.value.resource_group_name
}

locals {
  secrets = jsondecode(file("./secrets.json"))
  virtual_machines = flatten([
    for host_name, host_property in var.virtual_machines : [
      for count in range(1, host_property.deploy + 1) : {
        vm_name                = format("%s%02d", "${host_name}-", count)
        vm_resource_group_name = host_property.resource_group_name
        vm_image_source_type   = host_property.image_source_type
        vm_asg_name            = host_property.asg_name
        vm_subnet_name         = host_property.subnet_name
        vm_tags                = lookup(host_property, "tags", null)
        vm_shutdown_schedule   = host_property.shutdown_schedule
      }
    ]
    if host_property.deploy > 0
  ])
}

resource "azurerm_network_interface" "nic" {
  for_each            = { for entry in local.virtual_machines : entry.vm_name => entry }
  name                = "${each.key}-TRUSTED-01"
  resource_group_name = azurerm_resource_group.rg[each.value.vm_resource_group_name].name
  location            = azurerm_resource_group.rg[each.value.vm_resource_group_name].location

  ip_configuration {
    name                          = "${each.key}-CONFIG"
    subnet_id                     = azurerm_subnet.snet[each.value.vm_subnet_name].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_application_security_group_association" "nic_asg" {
  for_each                      = { for entry in local.virtual_machines : entry.vm_name => entry }
  network_interface_id          = azurerm_network_interface.nic[each.key].id
  application_security_group_id = azurerm_application_security_group.asg[each.value.vm_asg_name].id
}

resource "random_uuid" "rng" {
  keepers = {
    first = "${timestamp()}"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  for_each = {
    for entry in local.virtual_machines : entry.vm_name => entry
    if entry.vm_image_source_type == "Linux"
  }

  name                            = each.key
  resource_group_name             = azurerm_resource_group.rg[each.value.vm_resource_group_name].name
  location                        = azurerm_resource_group.rg[each.value.vm_resource_group_name].location
  admin_username                  = local.secrets.credentials.username
  admin_password                  = local.secrets.credentials.password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.nic[each.key].id]
  provision_vm_agent              = true
  source_image_id                 = data.azurerm_image.img[each.value.vm_image_source_type].id
  size                            = "Standard_D2s_v3"
  tags                            = each.value.vm_tags

  os_disk {
    name                 = "${each.key}-OS-DISK"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    replace_triggered_by = [random_uuid.rng]
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  for_each = {
    for entry in local.virtual_machines : entry.vm_name => entry
    if entry.vm_image_source_type == "Windows"
  }

  name                  = each.key
  resource_group_name   = azurerm_resource_group.rg[each.value.vm_resource_group_name].name
  location              = azurerm_resource_group.rg[each.value.vm_resource_group_name].location
  admin_username        = local.secrets.credentials.username
  admin_password        = local.secrets.credentials.password
  license_type          = "Windows_Server"
  network_interface_ids = [azurerm_network_interface.nic[each.key].id]
  provision_vm_agent    = true
  source_image_id       = data.azurerm_image.img[each.value.vm_image_source_type].id
  size                  = "Standard_D2s_v3"
  tags                  = each.value.vm_tags

  os_disk {
    name                 = "${each.key}-OS-DISK"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    replace_triggered_by = [random_uuid.rng]
  }
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "linux_auto_shutdown" {
  for_each = {
    for entry in local.virtual_machines : entry.vm_name => entry
    if entry.vm_image_source_type == "Linux"
  }

  virtual_machine_id    = azurerm_linux_virtual_machine.vm[each.key].id
  location              = azurerm_linux_virtual_machine.vm[each.key].location
  enabled               = each.value.vm_shutdown_schedule.enabled
  daily_recurrence_time = each.value.vm_shutdown_schedule.time
  timezone              = each.value.vm_shutdown_schedule.timezone

  notification_settings {
    enabled = false
  }
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "windows_auto_shutdown" {
  for_each = {
    for entry in local.virtual_machines : entry.vm_name => entry
    if entry.vm_image_source_type == "Windows"
  }

  virtual_machine_id    = azurerm_windows_virtual_machine.vm[each.key].id
  location              = azurerm_windows_virtual_machine.vm[each.key].location
  enabled               = each.value.vm_shutdown_schedule.enabled
  daily_recurrence_time = each.value.vm_shutdown_schedule.time
  timezone              = each.value.vm_shutdown_schedule.timezone

  notification_settings {
    enabled = false
  }
}
