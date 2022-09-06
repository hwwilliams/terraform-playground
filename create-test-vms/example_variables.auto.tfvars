#############
## General ##
#############
resource_groups = {
  "<resource_group_name>" = "<region_name>"
}

#############
## Network ##
#############
application_security_groups = {
  "<application_security_group_name>" = "<resource_group_name>",
}

network_security_groups = {
  "<network_security_group_name>" = {
    resource_group_name = "<resource_group_name>",
    associated_subnets  = ["<subnet_name>"],
    security_rules = {
      "AllowInboundHTTPS" = {
        direction                               = "Inbound",
        access                                  = "Allow",
        protocol                                = "Tcp",
        destination_application_security_groups = ["<application_security_group_name>"],
        destination_port_range                  = "443",
        source_address_prefix                   = "*",
        source_port_range                       = "*"
      }
    }
  }
}

subnets = {
  "<subnet_name>" = ["<subnet_cidr>"]
}

virtual_network = {
  name                = "<virtual_network_name>",
  resource_group_name = "<resource_group_name>"
}

######################
## Virtual Machines ##
######################
virtual_machines = {
  "<linux_vm_name_prefix>" = {
    deploy              = 0,
    resource_group_name = "<resource_group_name>",
    image_source_type   = "Linux",
    asg_name            = "<application_security_group_name>",
    subnet_name         = "<subnet_name>",
    tags                = {}
    shutdown_schedule = {
      enabled  = true,
      time     = 1000,
      timezone = "Eastern Standard Time"
    }
  },
  "<windows_vm_name_prefix>" = {
    deploy              = 0,
    resource_group_name = "<resource_group_name>",
    image_source_type   = "Windows",
    asg_name            = "<application_security_group_name>",
    subnet_name         = "<subnet_name>",
    tags                = {}
    shutdown_schedule = {
      enabled  = true,
      time     = 1000,
      timezone = "Eastern Standard Time"
    }
  }
}

virtual_machine_image_source = {
  "Linux" = {
    name                = "<managed_image_name>",
    resource_group_name = "<resource_group_name>",
  },
  "Windows" = {
    name                = "<managed_image_name>"
    resource_group_name = "<resource_group_name>",
  }
}
