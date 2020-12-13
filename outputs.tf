output "public_subnet_id" {
  description = "Id of the public subnet (calculated from the subnet name)"
  value = data.aws_subnet.public.id
}

output "private_subnet_id" {
  description = "Id of the private subnet (calculated from the subnet name)"
  value = data.aws_subnet.private.id
}

output "security_group_id" {
  description = "Id of the security group for the instance (calculated from the security group name)"
  value = data.aws_security_group.cfclient.id
}

output "debian_ami_id" {
  description = "Id of the latest AMI of Debian 10 for amd64 processors"
  value = data.aws_ami.debian_official.id
}

output "eip_address" {
  description = "Public (elastic) IP for the instance"
  value = aws_eip.cfengine.public_ip
}

output "eip_name" {
  description = "DNS name associated to the public (elastic) IP for the instance"
  value = aws_eip.cfengine.public_dns
}

output "private_ip" {
  description = "Private IP for the instance"
  value = local.private_ip
}

output "ssh_command" {
  description = "Command to run to connect to the instance via SSH"
  value = "ssh admin@${aws_eip.cfengine.public_dns}"
}

output "spot_instance_request_id" {
  description = "Spot instance request id (or null if on-demand instances are used)"
  value = local.spot_instance_request_id
}

output "instance_id" {
  description = "Id for the instance running the service"
  value = local.instance_id
}
