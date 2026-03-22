# ============================================================
# TERRAFORM PROVIDER CONFIGURATION
# ============================================================
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# ============================================================
# RESOURCE GROUP
# ============================================================
resource "azurerm_resource_group" "rg" {
  name     = "react-app-rg"
  location = "Canada Central"
}

# ============================================================
# VIRTUAL NETWORK
# ============================================================
resource "azurerm_virtual_network" "vnet" {
  name                = "react-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# ============================================================
# SUBNET
# ============================================================
resource "azurerm_subnet" "subnet" {
  name                 = "react-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# ============================================================
# NETWORK SECURITY GROUP
# Opens port 22 (SSH) and port 80 (HTTP)
# ============================================================
resource "azurerm_network_security_group" "nsg" {
  name                = "react-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# ============================================================
# PUBLIC IP ADDRESS
# ============================================================
resource "azurerm_public_ip" "public_ip" {
  name                = "react-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# ============================================================
# NETWORK INTERFACE
# ============================================================
resource "azurerm_network_interface" "nic" {
  name                = "react-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# ============================================================
# CONNECT NSG TO NETWORK INTERFACE
# ============================================================
resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# ============================================================
# VIRTUAL MACHINE — Ubuntu 20.04
# ============================================================
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "react-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_D2s_v3"

  admin_username                  = "azureuser"
  admin_password                  = "Oluwafemi11@@"
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
}

# ============================================================
# OUTPUT — Public IP printed after deployment
# ============================================================
output "public_ip_address" {
  value       = azurerm_public_ip.public_ip.ip_address
  description = "SSH and browser access: use this IP"
}

output "ssh_command" {
  value       = "ssh azureuser@${azurerm_public_ip.public_ip.ip_address}"
  description = "Run this command to connect to your VM"
}