#!/bin/bash
# MCP Registry EC2 Setup Script
# This script sets up an nginx web server to host the MCP registry and JAR files

set -e

echo "========================================="
echo "MCP Registry EC2 Setup"
echo "========================================="

# Update system
echo "Updating system packages..."
sudo yum update -y || sudo apt-get update -y

# Install nginx
echo "Installing nginx..."
if command -v yum &> /dev/null; then
    sudo yum install -y nginx
elif command -v apt-get &> /dev/null; then
    sudo apt-get install -y nginx
fi

# Install certbot for SSL
echo "Installing certbot for SSL certificates..."
if command -v yum &> /dev/null; then
    sudo yum install -y certbot python3-certbot-nginx
elif command -v apt-get &> /dev/null; then
    sudo apt-get install -y certbot python3-certbot-nginx
fi

# Create directory structure
echo "Creating directory structure..."
sudo mkdir -p /var/www/mcp-registry
sudo mkdir -p /var/www/mcp-registry/jars

# Set permissions
sudo chown -R ec2-user:ec2-user /var/www/mcp-registry || sudo chown -R ubuntu:ubuntu /var/www/mcp-registry

echo "========================================="
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Upload files using: scp registry.json *.jar ec2-user@<IP>:/var/www/mcp-registry/"
echo "2. Run: sudo bash configure-nginx.sh"
echo "3. Set up SSL: sudo certbot --nginx -d your-domain.com"
echo "========================================="
