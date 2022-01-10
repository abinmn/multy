config {
  location = "ireland"
  clouds   = ["aws", "azure"]
}
multy "virtual_network" "example_vn" {
  name       = "example_vn"
  cidr_block = "10.0.0.0/16"
}
multy "subnet" "subnet1" {
  name               = "subnet1"
  cidr_block         = "10.0.1.0/24"
  virtual_network_id = example_vn.id
}
multy "subnet" "subnet2" {
  name               = "subnet2"
  cidr_block         = "10.0.2.0/24"
  virtual_network_id = example_vn.id
  availability_zone  = 2
}
multy "subnet" "subnet3" {
  name               = "subnet3"
  cidr_block         = "10.0.3.0/24"
  virtual_network_id = example_vn.id
}
multy route_table "rt" {
  name               = "test-rt"
  virtual_network_id = example_vn.id
  routes             = [
    {
      cidr_block  = "0.0.0.0/0"
      destination = "internet"
    }
  ]
}
multy route_table_association rta {
  route_table_id = rt.id
  subnet_id      = subnet3.id
}
multy "database" "example_db" {
  name           = "example-db"
  size           = "nano"
  engine         = "mysql"
  engine_version = "5.7"
  storage        = 10
  db_username    = "multyadmin"
  db_password    = "multy$Admin123!"
  subnet_ids     = [
    subnet1.id,
    subnet2.id,
  ]
}
multy "virtual_machine" "vm" {
  name      = "test-vm"
  os        = "linux"
  size      = "micro"
  user_data = "sudo su; yum update -y; yum install -y httpd.x86_64; systemctl start httpd.service; systemctl enable httpd.service; touch /var/www/html/index.html;"
  subnet_id = subnet3.id
  public_ip = true
}
multy "network_security_group" nsg2 {
  name               = "test-nsg2"
  virtual_network_id = example_vn.id
  rules              = [
    {
      protocol   = "tcp"
      priority   = "100"
      action     = "allow"
      from_port  = "80"
      to_port    = "80"
      cidr_block = "0.0.0.0/0"
      direction  = "both"
    }, {
      protocol   = "tcp"
      priority   = "120"
      action     = "allow"
      from_port  = "22"
      to_port    = "22"
      cidr_block = "0.0.0.0/0"
      direction  = "both"
    }, {
      protocol   = "tcp"
      priority   = "140"
      action     = "allow"
      from_port  = "443"
      to_port    = "443"
      cidr_block = "0.0.0.0/0"
      direction  = "both"
    }
  ]
}