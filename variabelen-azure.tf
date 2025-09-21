variable "location" {
  type    = string
  default = "West Europe"
}

variable "resource_group_name" {
  type    = string
  default = "S1201431"
}

variable "virtual_network_name" {
  type    = string
  default = "azurerm-vnet"
}

variable "address_space" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}

variable "subnet_name" {
  type    = string
  default = "azurerm-internal"
}

variable "subnet_address_prefixes" {
  type    = list(string)
  default = ["10.0.2.0/24"]
}

variable "vm_count" {
  type    = number
  default = 2
}

variable "vm_size" {
  type    = string
  default = "Standard_DS1_v2"
}

variable "admin_username" {
  type    = string
  default = "iac"
}

variable "ssh_key_name" {
  type    = string
  default = "azure-ssh-key"
}

variable "nsg_name" {
  type    = string
  default = "ssh-nsg"
}

variable "allocation_method" {
  type    = string
  default = "Static"
}

variable "sku" {
  type    = string
  default = "Standard"
}
