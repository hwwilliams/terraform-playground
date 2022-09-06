#############
## General ##
#############
variable "resource_groups" {
  description = "Map of resource groups and their location."
  type        = map(string)
}

#############
## Network ##
#############
variable "application_security_groups" {
  description = "Map of application security groups and resource group name."
  type        = map(string)
}

variable "network_security_groups" {
  description = "Map of Network security groups, associated subnets, and security rules."
  type = map(object({
    resource_group_name = string
    associated_subnets  = list(string)
    security_rules = map(object({
      direction                               = string
      access                                  = string
      protocol                                = string
      destination_address_prefix              = optional(string)
      destination_address_prefixes            = optional(list(string))
      destination_application_security_groups = optional(list(string))
      destination_port_range                  = optional(string)
      destination_port_ranges                 = optional(list(string))
      source_address_prefix                   = optional(string)
      source_address_prefixes                 = optional(list(string))
      source_application_security_groups      = optional(list(string))
      source_port_range                       = optional(string)
      source_port_ranges                      = optional(list(string))
    }))
  }))
}

variable "subnets" {
  description = "Map of subnets for the virtual network."
  type        = map(list(string))
}

variable "virtual_network" {
  description = "Object for virtual networks."
  type = object({
    name                = string
    resource_group_name = string
  })
}

######################
## Virtual Machines ##
######################
variable "virtual_machines" {
  description = "Map of virtual machine nodes."
  type = map(object({
    deploy              = number
    resource_group_name = string
    image_source_type   = string
    asg_name            = string
    subnet_name         = string
    tags                = optional(map(string))
    shutdown_schedule = object({
      enabled  = bool
      time     = number
      timezone = string
    })
  }))
}

variable "virtual_machine_image_source" {
  description = "Map of virtual machine image sources."
  type = map(object({
    name                = string
    resource_group_name = string
  }))
}
