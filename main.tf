# configure alicloud provider to initilize terraform
provider "alicloud" {
  access_key = var.access_key
  secret_key = var.secret_key
  region = "me-central-1"
}


variable "name" {
  default = "terraform-alicloud-lab"
}

# add the zones to the server
data "alicloud_zones" "zones-lab" {
  available_disk_category = "cloud_efficiency"
  available_resource_creation = "VSwitch"
}

# create a vpc
resource "alicloud_vpc" "vpc-lab" {
  vpc_name   = "lab-3"
  cidr_block = "10.0.0.0/8"
}

# crate a vSwitch for the public network
resource "alicloud_vswitch" "public" {
  vswitch_name = "public-vSwitch-lab"
  vpc_id     = alicloud_vpc.vpc-lab.id
  cidr_block = "10.0.5.0/24"
  zone_id    = data.alicloud_zones.zones-lab.zones.0.id
}

# Create a security groups and rules
resource "alicloud_security_group" "http-lab" {
  name        = "lab-week3"
  description = "http security group"
  vpc_id = alicloud_vpc.vpc-lab.id
}

# ssh rule
resource "alicloud_security_group_rule" "allow-web-ssh" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  security_group_id = alicloud_security_group.http-lab.id
  cidr_ip           = "0.0.0.0/0"
}

# http rule
resource "alicloud_security_group_rule" "allow-web-http" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "80/80"
  priority          = 1
  security_group_id = alicloud_security_group.http-lab.id
  cidr_ip           = "0.0.0.0/0"
}

# create a key
resource "alicloud_ecs_key_pair" "myKey-lab" {
  key_pair_name = "lab-key"
  key_file = "la3_bKey.pem"
}

# create ECS
resource "alicloud_instance" "lap-project" {
  availability_zone = data.alicloud_zones.zones-lab.zones.0.id
  security_groups   = [alicloud_security_group.http-lab.id]

  system_disk_name           = "YazeedAlturki"
  instance_type              = "ecs.g6.large"
  system_disk_category       = "cloud_essd"
  system_disk_size           = 40
  image_id                   = "ubuntu_24_04_x64_20G_alibase_20240812.vhd"
  instance_name              = "week3-lab"
  vswitch_id                 = alicloud_vswitch.public.id
  internet_max_bandwidth_out = 100
  internet_charge_type       = "PayByTraffic"
  instance_charge_type       = "PostPaid"
  key_name                   = alicloud_ecs_key_pair.myKey-lab.key_pair_name
  user_data = base64encode(file("nginx-setup.sh"))
}

output "lap-project_server_public_ip"{
    value = alicloud_instance.lap-project.public_ip
}
