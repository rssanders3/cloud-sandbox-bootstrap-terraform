# Define variables for sensitive information
variable "region" {
  default = "East US"
}
variable "local_public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}


terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.75.0"
    }
  }

  required_version = ">= 1.5.7"
}

# Configure the Azure provider
provider "azurerm" {
  features {}
  skip_provider_registration = true
}


# Resource Group
resource "azurerm_resource_group" "vm_resource_group" {
  name     = "vm-resource-group"
  location = var.region
}

resource "azurerm_virtual_network" "vm_virtual_network" {
  name                = "vm-virtual-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.vm_resource_group.location
  resource_group_name = azurerm_resource_group.vm_resource_group.name
}

resource "azurerm_subnet" "vm_subnet" {
  name                 = "vm-subnet"
  resource_group_name  = azurerm_resource_group.vm_resource_group.name
  virtual_network_name = azurerm_virtual_network.vm_virtual_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "vm_network_security_group" {
  name                = "vm-network-security-group"
  location            = azurerm_resource_group.vm_resource_group.location
  resource_group_name = azurerm_resource_group.vm_resource_group.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "vm_network_interface" {
  name                = "vm-network-interface"
  location            = azurerm_resource_group.vm_resource_group.location
  resource_group_name = azurerm_resource_group.vm_resource_group.name

  ip_configuration {
    name                          = "ip-config"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"

    public_ip_address_id = azurerm_public_ip.vm_public_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "vm_network_interface_security_group_association" {
  network_interface_id      = azurerm_network_interface.vm_network_interface.id
  network_security_group_id = azurerm_network_security_group.vm_network_security_group.id
}

resource "azurerm_public_ip" "vm_public_ip" {
  name                = "vm-public-ip"
  location            = azurerm_resource_group.vm_resource_group.location
  resource_group_name = azurerm_resource_group.vm_resource_group.name
  allocation_method   = "Dynamic"
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm"
  location            = azurerm_resource_group.vm_resource_group.location
  resource_group_name = azurerm_resource_group.vm_resource_group.name
  size                = "Standard_B2ms"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.vm_network_interface.id
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file(var.local_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}


output "azure_vm_public_ip" {
  value = azurerm_linux_virtual_machine.vm.public_ip_address
}
output "azure_vm_ssh_cmd" {
  value = "ssh -i ${replace(var.local_public_key_path, ".pub", "")} azureuser@${azurerm_linux_virtual_machine.vm.public_ip_address}"
}
