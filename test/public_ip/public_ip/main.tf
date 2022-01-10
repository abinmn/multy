resource "aws_vpc" "example_vn_aws" {
  tags = {
    Name = "example_vn"
  }

  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}
resource "aws_internet_gateway" "example_vn_aws" {
  tags = {
    Name = "example_vn"
  }

  vpc_id = aws_vpc.example_vn_aws.id
}
resource "aws_default_security_group" "example_vn_aws" {
  tags = {
    Name = "example_vn"
  }

  vpc_id = aws_vpc.example_vn_aws.id

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }
}
resource "aws_eip" "ip_aws" {
  tags = {
    Name = "test-ip"
  }

  network_interface = aws_network_interface.public-nic_aws.id
}
resource "aws_network_interface" "private-nic_aws" {
  tags = {
    Name = "test-private-nic"
  }

  subnet_id = aws_subnet.subnet_aws.id
}
resource "aws_network_interface" "public-nic_aws" {
  tags = {
    Name = "test-public-nic"
  }

  subnet_id = aws_subnet.subnet_aws.id
}
resource "aws_subnet" "subnet_aws" {
  tags = {
    Name = "subnet"
  }

  cidr_block        = "10.0.2.0/24"
  vpc_id            = aws_vpc.example_vn_aws.id
  availability_zone = "eu-west-1b"
}
resource "azurerm_virtual_network" "example_vn_azure" {
  resource_group_name = azurerm_resource_group.vn-rg.name
  name                = "example_vn"
  location            = "northeurope"
  address_space       = ["10.0.0.0/16"]
}
resource "azurerm_route_table" "example_vn_azure" {
  resource_group_name = azurerm_resource_group.vn-rg.name
  name                = "example_vn"
  location            = "northeurope"

  route {
    name           = "local"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VnetLocal"
  }
}
resource "azurerm_public_ip" "ip_azure" {
  resource_group_name = azurerm_resource_group.pip-rg.name
  name                = "test-ip"
  location            = "northeurope"
  allocation_method   = "Static"
}
resource "azurerm_resource_group" "nic-rg" {
  name     = "nic-rg"
  location = "northeurope"
}
resource "azurerm_resource_group" "pip-rg" {
  name     = "pip-rg"
  location = "northeurope"
}
resource "azurerm_network_interface" "private-nic_azure" {
  resource_group_name = azurerm_resource_group.nic-rg.name
  name                = "test-private-nic"
  location            = "northeurope"

  ip_configuration {
    name                          = "internal"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.subnet_azure.id
    primary                       = true
  }
}
resource "azurerm_network_interface" "public-nic_azure" {
  resource_group_name = azurerm_resource_group.nic-rg.name
  name                = "test-public-nic"
  location            = "northeurope"

  ip_configuration {
    name                          = "internal"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.subnet_azure.id
    primary                       = true
  }
}
resource "azurerm_subnet" "subnet_azure" {
  resource_group_name  = azurerm_resource_group.vn-rg.name
  name                 = "subnet"
  address_prefixes     = ["10.0.2.0/24"]
  virtual_network_name = azurerm_virtual_network.example_vn_azure.name
}
resource "azurerm_subnet_route_table_association" "subnet_azure" {
  subnet_id      = azurerm_subnet.subnet_azure.id
  route_table_id = azurerm_route_table.example_vn_azure.id
}
resource "azurerm_resource_group" "vn-rg" {
  name     = "vn-rg"
  location = "northeurope"
}
provider "aws" {
  region = "eu-west-1"
}
provider "azurerm" {
  features {}
}