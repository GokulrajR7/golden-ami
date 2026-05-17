#!/bin/bash

set -e

echo "Updating system..."
dnf update -y

echo "Installing basic tools..."
dnf install -y git wget unzip tar

echo "Installing Docker..."
dnf install -y docker

systemctl enable docker
systemctl start docker

usermod -aG docker ec2-user

echo "Installing Java 21..."
dnf install -y java-21-amazon-corretto

echo "Cleaning packages..."
dnf clean all

echo "Validation..."

java -version
docker --version
git --version

echo "Golden AMI setup completed."
