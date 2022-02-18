#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# Configure CFEngine repository
echo "Configuring CFEngine APT repository"
wget -q -O /etc/apt/trusted.gpg.d/cfengine-community-keyring.asc  https://cfengine-package-repos.s3.amazonaws.com/pub/gpg.key
echo "deb https://cfengine-package-repos.s3.amazonaws.com/pub/apt/packages stable main" > /etc/apt/sources.list.d/cfengine-community.list

# Install package and hold, so that it doesn't get automatically upgraded when it shouldn't
echo "Updating package cache and installing CFEngine"
apt-get update
apt-get install -y cfengine-community=${package_version}
echo cfengine-community hold | sudo dpkg --set-selections

echo "Bootstrapping cfengine client..."
cf-agent --bootstrap ${cfengine_server}

echo "CFEngine client provisioning completed"
