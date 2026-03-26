terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.64"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

# VARIABLES
variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}

variable "location" {
  default = "switzerlandnorth"
}

# RESOURCE GROUP
resource "azurerm_resource_group" "rg" {
  name     = "rg-devops"
  location = var.location
  tags = {
    environment = "dev"
    project     = "k8s"
  }
}

# VIRTUAL NETWORK
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-devops"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

# SUBNET
resource "azurerm_subnet" "subnet" {
  name                 = "subnet-devops"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# NETWORK SECURITY GROUP
resource "azurerm_network_security_group" "nsg" {
  name                = "devops-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"  # à limiter à ton IP pour plus de sécurité
    destination_address_prefix = "*"
  }
}

# PUBLIC IPs
resource "azurerm_public_ip" "pip_master" {
  name                = "pip-master"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "pip_worker" {
  name                = "pip-worker"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# NETWORK INTERFACES
resource "azurerm_network_interface" "nic_master" {
  name                = "nic-master"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.10"
    public_ip_address_id          = azurerm_public_ip.pip_master.id
  }
}

resource "azurerm_network_interface" "nic_worker" {
  name                = "nic-worker"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.11"
    public_ip_address_id          = azurerm_public_ip.pip_worker.id
  }
}

# NSG ASSOCIATION
resource "azurerm_network_interface_security_group_association" "master_nsg" {
  network_interface_id      = azurerm_network_interface.nic_master.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_interface_security_group_association" "worker_nsg" {
  network_interface_id      = azurerm_network_interface.nic_worker.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# VM MASTER
resource "azurerm_linux_virtual_machine" "vm_master" {
  name                = "k8s-master"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  size                = "Standard_B2ls_v2"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.nic_master.id
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("${path.module}/ssh_key/id_rsa.pub")
  }

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

# VM WORKER
resource "azurerm_linux_virtual_machine" "vm_worker" {
  name                = "k8s-worker"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  size                = "Standard_B2ls_v2"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.nic_worker.id
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("${path.module}/ssh_key/id_rsa.pub")
  }

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