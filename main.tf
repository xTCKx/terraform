terraform {
  required_providers {
    esxi = {
      source = "registry.terraform.io/josenk/esxi"
    }
    azurerm = {
      source = "hashicorp/azurerm"
    }
    local = {
      source = "hashicorp/local"
    }
  }
}


provider "esxi" {
  esxi_hostname = var.esxi_hostname
  esxi_hostport = var.esxi_hostport
  esxi_hostssl  = var.esxi_hostssl
  esxi_username = var.esxi_username
  esxi_password = var.esxi_password
}

provider "azurerm" {
  resource_provider_registrations = "none"
  subscription_id = "c064671c-8f74-4fec-b088-b53c568245eb"
  features{}
}

resource "esxi_guest" "webserver" {
  count      = var.webserver_count
  guest_name = "webserver+${count.index +1}"
  disk_store = var.disk_store
  memsize    = var.vm_memsize
  numvcpus   = var.vm_numvcpus

  ovf_source = var.ovf_source
  network_interfaces {
    virtual_network = var.virtual_network
  }

  guestinfo = {
    "metadata"          = filebase64("metadata.yaml")
    "metadata.encoding" = "base64"
    "userdata"          = filebase64("userdata.yaml")
    "userdata.encoding" = "base64"
  }

}

resource "esxi_guest" "databaseserver" {
  guest_name = "databaseserver"
  disk_store = var.disk_store
  memsize    = var.vm_memsize
  numvcpus   = var.vm_numvcpus

  ovf_source = var.ovf_source
  network_interfaces {
    virtual_network = var.virtual_network
  }

  guestinfo = {
    "metadata"          = filebase64("metadata.yaml")
    "metadata.encoding" = "base64"
    "userdata"          = filebase64("userdata.yaml")
    "userdata.encoding" = "base64"
  }
}


resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = "West Europe"
}

resource "azurerm_virtual_network" "main" {
  name                = var.virtual_network_name
  address_space       = var.address_space
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "internal" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.subnet_address_prefixes
}

resource "azurerm_public_ip" "pip" {
  count = 2
  name                = "azurerm-pip${count.index+1}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = var.allocation_method
  sku                 = var.sku
}

resource "azurerm_network_interface" "main" {
  count = 2
  name                = "azurerm-nic${count.index+1}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip[count.index].id
  }
}

resource "azurerm_network_security_group" "ssh-nsg" {
  name                = "ssh-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  security_rule {
    access                     = "Allow"
    direction                  = "Inbound"
    name                       = "ssh-nsg"
    priority                   = 100
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "22"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.internal.id
  network_security_group_id = azurerm_network_security_group.ssh-nsg.id
}

data "azurerm_ssh_public_key" "key" {
  name                = "azure-ssh-key"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_linux_virtual_machine" "main" {
  count                           = 2
  name                            = "azurerm-vm${count.index+1}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.main[count.index].id]
  custom_data                     = base64encode(file("cloud-init.yml"))

  admin_ssh_key {
    username   = var.admin_username
    public_key = data.azurerm_ssh_public_key.key.public_key
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}

# Output blocks to capture all VM IP addresses
output "esxi_webserver_ips" {
  description = "IP addresses of ESXi webserver VMs"
  value       = esxi_guest.webserver[*].ip_address
}

output "esxi_databaseserver_ip" {
  description = "IP address of ESXi database server VM"
  value       = esxi_guest.databaseserver.ip_address
}

output "azure_vm_public_ips" {
  description = "Public IP addresses of Azure VMs"
  value       = azurerm_public_ip.pip[*].ip_address
}

output "azure_vm_private_ips" {
  description = "Private IP addresses of Azure VMs"
  value       = azurerm_network_interface.main[*].private_ip_address
}

# Local file resource to save all IP addresses
resource "local_file" "vm_ips" {
  filename = "${path.module}/vm_ip_addresses.txt"
  content = <<-EOT
VM IP Addresses Report
Generated on: ${timestamp()}

ESXi Virtual Machines:
----------------------
${join("\n", [for i, ip in esxi_guest.webserver[*].ip_address : "Webserver ${i + 1}: ${ip}"])}
Database Server: ${esxi_guest.databaseserver.ip_address}

Azure Virtual Machines:
-----------------------
${join("\n", [for i, ip in azurerm_public_ip.pip[*].ip_address : "Azure VM ${i + 1}:\n  - Public IP:  ${ip}\n  - Private IP: ${azurerm_network_interface.main[i].private_ip_address}"])}

Summary:
--------
Total ESXi VMs: ${var.webserver_count + 1}
Total Azure VMs: 2
Total VMs: ${var.webserver_count + 3}

All IP Addresses (for quick reference):
${join("\n", esxi_guest.webserver[*].ip_address)}
${esxi_guest.databaseserver.ip_address}
${join("\n", azurerm_public_ip.pip[*].ip_address)}
${join("\n", azurerm_network_interface.main[*].private_ip_address)}
EOT
  
  depends_on = [
    esxi_guest.webserver,
    esxi_guest.databaseserver,
    azurerm_linux_virtual_machine.main,
    azurerm_public_ip.pip
  ]
}
