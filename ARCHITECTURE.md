# tf-mod-cfengine-client: how it works

# Architecture

The module will create:

1. an AWS instance (a spot instance unless you specify otherwise)
2. a public elastic IP that will be attached to the AWS istance to make it accessible from the Internet, according to the rules established by the assigned security groups.

The instance will be bootstrapped against the policy server whose IP or hostname are given in the variable `cfengine_server`.


# Prerequisites

1. a VPC with a public subnet;
2. the public subnet must be accessible from/have access to the Internet;
3. the subnets are identified by unique `Name` tags;
4. the CFEngine server is accessible by this instance;
5. a security group applicable to the instance exists **before** the instance is created, and is tagged with a unique `Name` tag;
6. the module creates the instance using the latest Debian 10 AMI, unless you specify a different AMI ID; please notice that **the user data assumes a Debian system**: using a Debian derivative **may** work, using non-Debian-based distributions will **not** work.
7. a functional AWS CLI is required to properly tag spot instances; if the command is not available, the provisioning of the instance will continue, but the instance won't be tagged properly

The spot instance request will expire after six months. New Debian AMIs with security updates are released more or less every three months on average, and replacing a server with a new one is a seamless process thanks to Terraform and this module. Six months should give you plenty of space to recycle existing instances with new ones.


