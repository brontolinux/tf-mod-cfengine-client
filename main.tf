/*
* I built this module to create test clients for my CFEngine set-up. The set-up is very specific and may not be useful in a general case. The module itself however could be useful as a starting point for building generic test clients.
*
* See the [ARCHITECTURE](ARCHITECTURE.md) document for details.
*/

########################################################################
# Data collection

# Subnets
data "aws_subnet" "public" {
  tags = {
    Name = var.pub_subnet_name
  }
}

# Security groups
data "aws_security_group" "cfclient" {
  name = var.instance_sg_name
}

# Official Debian 10 AMI, latest
data "aws_ami" "debian_official" {
  most_recent = true
  name_regex  = "^debian-11-amd64-.+"

  # Owner of official debian 10 AMIs
  # See https://wiki.debian.org/Cloud/AmazonEC2Image/Buster
  owners = ["136693071363"]

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Render templates for cloud-init
data "template_file" "cloud_init" {
  template = file("${path.module}/user_data/cloud-init.tpl")

  vars = {
    instance_name            = var.instance_name
  }
}

data "template_file" "init_sh" {
  template = file("${path.module}/user_data/init.sh.tpl")

  vars = {
    package_version = var.cfengine_deb_package_version
    cfengine_server = var.cfengine_server
  }
}

data "template_cloudinit_config" "cloud_init" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "cloud-init"
    content_type = "text/cloud-config"
    content      = data.template_file.cloud_init.rendered
  }

  part {
    filename     = "00-init.sh"
    content_type = "text/x-shellscript"
    content      = data.template_file.init_sh.rendered
  }
}

########################################################################
# Local variables
locals {
  spot_count     = var.spot_instance ? 1 : 0
  ondemand_count = var.spot_instance ? 0 : 1
  ami_id         = var.ami_id == "latest" ? data.aws_ami.debian_official.id : var.ami_id

  private_ip               = var.spot_instance ? aws_spot_instance_request.cfengine[0].private_ip : aws_instance.cfengine[0].private_ip
  spot_instance_request_id = var.spot_instance ? aws_spot_instance_request.cfengine[0].id : null
  instance_id              = var.spot_instance ? aws_spot_instance_request.cfengine[0].spot_instance_id : aws_instance.cfengine[0].id

  # spot request expires in 6 months
  spot_request_expiration = timeadd(timestamp(), "4320h")
}

########################################################################
# Resources

# EC2 instance
resource "aws_spot_instance_request" "cfengine" {
  count = local.spot_count

  # There is no point in having a permanent request. If the instance terminates
  # and a new one is created, the elastic IP won't be attached to the new
  # instance. As a result, I'll end up paying for both the instance and the
  # unattached IP. Not smart. We go for one-time
  spot_type            = "one-time"
  wait_for_fulfillment = true

  ami           = local.ami_id
  instance_type = var.instance_type
  key_name      = var.ssh_key_name

  vpc_security_group_ids = [data.aws_security_group.cfclient.id]

  subnet_id = data.aws_subnet.public.id
  #associate_public_ip_address = false

  user_data_base64 = data.template_cloudinit_config.cloud_init.rendered

  valid_until = local.spot_request_expiration

  tags = {
    Name = var.instance_name
  }

  volume_tags = {
    instanceName = var.instance_name
  }

  provisioner "local-exec" {
    command    = "aws ec2 create-tags --tags Key=Name,Value=${var.instance_name} --resources ${self.spot_instance_id}"
    on_failure = continue
  }

  lifecycle {
    ignore_changes = [
      # ignore the spot request expiration date, changes at every run
      valid_until
    ]
  }
}

resource "aws_instance" "cfengine" {
  count = local.ondemand_count

  ami           = local.ami_id
  instance_type = var.instance_type
  key_name      = var.ssh_key_name

  vpc_security_group_ids = [data.aws_security_group.cfclient.id]

  subnet_id = data.aws_subnet.public.id
  #associate_public_ip_address = false

  user_data_base64 = data.template_cloudinit_config.cloud_init.rendered

  tags = {
    Name = var.instance_name
  }

  volume_tags = {
    instanceName = var.instance_name
  }
}

# Create the EIP and the association separately, so that the IP is kept
# when the instance is recycled
resource "aws_eip" "cfengine" {
  vpc = true

  tags = {
    Name         = "${var.instance_name}.eip"
    instanceName = var.instance_name
  }
}

resource "aws_eip_association" "cfengine" {
  instance_id   = local.instance_id
  allocation_id = aws_eip.cfengine.id
}
