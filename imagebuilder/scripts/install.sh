#!/bin/bash

set -e

echo "Updating system..."
sudo dnf update -y

echo "Installing basic tools..."
sudo dnf install -y git wget unzip tar

echo "Installing Docker..."
sudo dnf install -y docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user

echo "Installing Java 21..."
sudo dnf install -y java-21-amazon-corretto

# Optional NodeJS
# sudo dnf module enable nodejs:20 -y
# sudo dnf install -y nodejs

echo "Cleaning packages..."
sudo dnf clean all

echo "Validation..."

java -version
docker --version
git --version

echo "Golden AMI setup completed."
