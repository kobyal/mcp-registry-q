#!/bin/bash
# Configure nginx for MCP Registry

set -e

echo "========================================="
echo "Configuring nginx for MCP Registry"
echo "========================================="

# Create nginx configuration
cat > /tmp/mcp-registry.conf << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name _;

    root /var/www/mcp-registry;
    index registry.json;

    # Enable CORS for all origins (required for Amazon Q)
    add_header 'Access-Control-Allow-Origin' '*' always;
    add_header 'Access-Control-Allow-Methods' 'GET, OPTIONS' always;
    add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range' always;
    add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range' always;

    # Disable caching for registry.json
    location = /registry.json {
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
        add_header 'Access-Control-Allow-Origin' '*' always;
        try_files $uri =404;
    }

    # Cache JAR files for 1 year
    location ~* \.(jar)$ {
        add_header Cache-Control "public, max-age=31536000, immutable";
        add_header 'Access-Control-Allow-Origin' '*' always;
        try_files $uri =404;
    }

    # Enable directory listing for /jars
    location /jars/ {
        autoindex on;
        autoindex_exact_size off;
        autoindex_localtime on;
        add_header 'Access-Control-Allow-Origin' '*' always;
    }

    # Handle OPTIONS requests
    if ($request_method = 'OPTIONS') {
        add_header 'Access-Control-Allow-Origin' '*';
        add_header 'Access-Control-Allow-Methods' 'GET, OPTIONS';
        add_header 'Access-Control-Max-Age' 1728000;
        add_header 'Content-Type' 'text/plain; charset=utf-8';
        add_header 'Content-Length' 0;
        return 204;
    }

    # Logging
    access_log /var/log/nginx/mcp-registry-access.log;
    error_log /var/log/nginx/mcp-registry-error.log;
}
EOF

# Install configuration
echo "Installing nginx configuration..."
sudo mv /tmp/mcp-registry.conf /etc/nginx/conf.d/mcp-registry.conf

# Test nginx configuration
echo "Testing nginx configuration..."
sudo nginx -t

# Restart nginx
echo "Restarting nginx..."
sudo systemctl restart nginx
sudo systemctl enable nginx

# Check status
sudo systemctl status nginx

echo "========================================="
echo "Nginx configured successfully!"
echo ""
echo "Test your setup:"
echo "  curl http://localhost/registry.json"
echo ""
echo "To set up HTTPS with Let's Encrypt:"
echo "  sudo certbot --nginx -d your-domain.com"
echo ""
echo "Or for testing without domain (self-signed):"
echo "  sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \\"
echo "    -keyout /etc/ssl/private/nginx-selfsigned.key \\"
echo "    -out /etc/ssl/certs/nginx-selfsigned.crt"
echo "========================================="
