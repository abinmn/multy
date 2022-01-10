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
resource "aws_security_group" "nsg2_aws" {
  tags = {
    Name = "test-nsg2"
  }

  vpc_id = aws_vpc.example_vn_aws.id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["10.0.0.0/16"]
  }
}
resource "aws_route_table" "rt_aws" {
  tags = {
    Name = "test-rt"
  }

  vpc_id = aws_vpc.example_vn_aws.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example_vn_aws.id
  }
}
resource "aws_route_table_association" "rta_aws" {
  subnet_id      = aws_subnet.subnet1_aws.id
  route_table_id = aws_route_table.rt_aws.id
}
resource "aws_subnet" "subnet1_aws" {
  tags = {
    Name = "subnet1"
  }

  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.example_vn_aws.id
}
resource "aws_instance" "vm_aws" {
  tags = {
    Name = "test-vm"
  }

  ami                         = "ami-09d4a659cdd8677be"
  instance_type               = "t2.nano"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.subnet1_aws.id
  user_data_base64            = "IyEvYmluL2Jhc2ggLXhlCnN1ZG8gc3U7IHl1bSB1cGRhdGUgLXk7IHl1bSBpbnN0YWxsIC15IGh0dHBkLng4Nl82NDsgc3lzdGVtY3RsIHN0YXJ0IGh0dHBkLnNlcnZpY2U7IHN5c3RlbWN0bCBlbmFibGUgaHR0cGQuc2VydmljZTsgdG91Y2ggL3Zhci93d3cvaHRtbC9pbmRleC5odG1sOwplY2hvICI8aDE+SGVsbG8gZnJvbSBNdWx0eSBvbiBhd3M8L2gxPiIgPiAvdmFyL3d3dy9odG1sL2luZGV4Lmh0bWw="
}
resource "aws_instance" "vm2_aws" {
  tags = {
    Name = "test-vm2"
  }

  ami                         = "ami-09d4a659cdd8677be"
  instance_type               = "t2.nano"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.subnet1_aws.id
  user_data_base64            = "IyEvYmluL2Jhc2ggLXhlCnN1ZG8gc3U7ICB5dW0gdXBkYXRlIC15OyB5dW0gaW5zdGFsbCAteSBodHRwZC54ODZfNjQ7IHN5c3RlbWN0bCBzdGFydCBodHRwZC5zZXJ2aWNlOyBzeXN0ZW1jdGwgZW5hYmxlIGh0dHBkLnNlcnZpY2U7IHRvdWNoIC92YXIvd3d3L2h0bWwvaW5kZXguaHRtbDsKZWNobyAiPGgxPkhlbGxvIGZyb20gTXVsdHkgb24gYXdzPC9oMT4iID4gL3Zhci93d3cvaHRtbC9pbmRleC5odG1s"
  vpc_security_group_ids      = [aws_security_group.nsg2_aws.id]
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
resource "azurerm_resource_group" "nsg-rg" {
  name     = "nsg-rg"
  location = "northeurope"
}
resource "azurerm_network_security_group" "nsg2_azure" {
  resource_group_name = azurerm_resource_group.nsg-rg.name
  name                = "test-nsg2"
  location            = "northeurope"

  security_rule {
    name                       = "0"
    protocol                   = "tcp"
    priority                   = 120
    access                     = "Allow"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "22-22"
    destination_address_prefix = "*"
    direction                  = "Inbound"
  }

  security_rule {
    name                       = "1"
    protocol                   = "tcp"
    priority                   = 120
    access                     = "Allow"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "22-22"
    destination_address_prefix = "*"
    direction                  = "Outbound"
  }

  security_rule {
    name                       = "2"
    protocol                   = "tcp"
    priority                   = 140
    access                     = "Allow"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "443-443"
    destination_address_prefix = "*"
    direction                  = "Inbound"
  }

  security_rule {
    name                       = "3"
    protocol                   = "tcp"
    priority                   = 140
    access                     = "Allow"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "443-443"
    destination_address_prefix = "*"
    direction                  = "Outbound"
  }
}
resource "azurerm_route_table" "rt_azure" {
  resource_group_name = azurerm_resource_group.vn-rg.name
  name                = "test-rt"
  location            = "northeurope"

  route {
    name           = "internet"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }
}
resource "azurerm_subnet_route_table_association" "rta_azure" {
  subnet_id      = azurerm_subnet.subnet1_azure.id
  route_table_id = azurerm_route_table.rt_azure.id
}
resource "azurerm_subnet" "subnet1_azure" {
  resource_group_name  = azurerm_resource_group.vn-rg.name
  name                 = "subnet1"
  address_prefixes     = ["10.0.1.0/24"]
  virtual_network_name = azurerm_virtual_network.example_vn_azure.name
}
resource "azurerm_network_interface" "vm_azure" {
  resource_group_name = azurerm_resource_group.vm-rg.name
  name                = "test-vm"
  location            = "northeurope"

  ip_configuration {
    name                          = "external"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.subnet1_azure.id
    public_ip_address_id          = azurerm_public_ip.vm_azure.id
    primary                       = true
  }
}
resource "azurerm_public_ip" "vm_azure" {
  resource_group_name = azurerm_resource_group.vm-rg.name
  name                = "test-vm"
  location            = "northeurope"
  allocation_method   = "Static"
}
resource "azurerm_linux_virtual_machine" "vm_azure" {
  resource_group_name   = azurerm_resource_group.vm-rg.name
  name                  = "test-vm"
  location              = "northeurope"
  size                  = "Standard_B1ls"
  network_interface_ids = [azurerm_network_interface.vm_azure.id]
  custom_data           = "IyEvYmluL2Jhc2ggLXhlCnN1ZG8gc3U7IHl1bSB1cGRhdGUgLXk7IHl1bSBpbnN0YWxsIC15IGh0dHBkLng4Nl82NDsgc3lzdGVtY3RsIHN0YXJ0IGh0dHBkLnNlcnZpY2U7IHN5c3RlbWN0bCBlbmFibGUgaHR0cGQuc2VydmljZTsgdG91Y2ggL3Zhci93d3cvaHRtbC9pbmRleC5odG1sOwplY2hvICI8aDE+SGVsbG8gZnJvbSBNdWx0eSBvbiBhenVyZTwvaDE+IiA+IC92YXIvd3d3L2h0bWwvaW5kZXguaHRtbA=="

  os_disk {
    caching              = "None"
    storage_account_type = "Standard_LRS"
  }

  admin_username = "multyadmin"
  admin_password = "Multyadmin090#"

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7_9-gen2"
    version   = "latest"
  }

  disable_password_authentication = false
}
resource "azurerm_resource_group" "vm-rg" {
  name     = "vm-rg"
  location = "northeurope"
}
resource "azurerm_network_interface" "vm2_azure" {
  resource_group_name = azurerm_resource_group.vm-rg.name
  name                = "test-vm2"
  location            = "northeurope"

  ip_configuration {
    name                          = "external"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.subnet1_azure.id
    public_ip_address_id          = azurerm_public_ip.vm2_azure.id
    primary                       = true
  }
}
resource "azurerm_public_ip" "vm2_azure" {
  resource_group_name = azurerm_resource_group.vm-rg.name
  name                = "test-vm2"
  location            = "northeurope"
  allocation_method   = "Static"
}
resource "azurerm_network_interface_security_group_association" "vm2_azure" {
  network_interface_id      = azurerm_network_interface.vm2_azure.id
  network_security_group_id = azurerm_network_security_group.nsg2_azure.id
}
resource "azurerm_linux_virtual_machine" "vm2_azure" {
  resource_group_name   = azurerm_resource_group.vm-rg.name
  name                  = "test-vm2"
  location              = "northeurope"
  size                  = "Standard_B1ls"
  network_interface_ids = [azurerm_network_interface.vm2_azure.id]
  custom_data           = "IyEvYmluL2Jhc2ggLXhlCnN1ZG8gc3U7ICB5dW0gdXBkYXRlIC15OyB5dW0gaW5zdGFsbCAteSBodHRwZC54ODZfNjQ7IHN5c3RlbWN0bCBzdGFydCBodHRwZC5zZXJ2aWNlOyBzeXN0ZW1jdGwgZW5hYmxlIGh0dHBkLnNlcnZpY2U7IHRvdWNoIC92YXIvd3d3L2h0bWwvaW5kZXguaHRtbDsKZWNobyAiPGgxPkhlbGxvIGZyb20gTXVsdHkgb24gYXp1cmU8L2gxPiIgPiAvdmFyL3d3dy9odG1sL2luZGV4Lmh0bWw="

  os_disk {
    caching              = "None"
    storage_account_type = "Standard_LRS"
  }

  admin_username = "multyadmin"
  admin_password = "Multyadmin090#"

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7_9-gen2"
    version   = "latest"
  }

  disable_password_authentication = false
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