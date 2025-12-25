# EC2 MCP Registry Implementation Guide

Complete step-by-step guide to deploy your MCP registry on EC2 with HTTPS.

---

## Prerequisites

- AWS account with EC2 access
- SSH key pair for EC2 access
- Domain name (optional, for proper SSL certificate)
- Local files ready: registry.json, MCPServer-1.0.0-runner.jar, mssql-jdbc-12.4.2.jre11.jar

---

## Step 1: Launch EC2 Instance

### Option A: Using AWS Console

1. **Navigate to EC2 Console**
   - Go to AWS Console → EC2 → Launch Instance

2. **Configure Instance:**
   - **Name:** `mcp-registry-server`
   - **AMI:** Amazon Linux 2023 or Ubuntu Server 22.04 LTS
   - **Instance type:** t3.micro (1 GB RAM is sufficient)
   - **Key pair:** Select or create new key pair
   - **Network settings:**
     - Auto-assign public IP: Enable
     - Security group: Create new with rules:
       - SSH (22) from your IP
       - HTTP (80) from anywhere (0.0.0.0/0)
       - HTTPS (443) from anywhere (0.0.0.0/0)
   - **Storage:** 8 GB gp3 (default is fine)

3. **Launch Instance**

### Option B: Using AWS CLI

```bash
# Create security group
aws ec2 create-security-group \
  --group-name mcp-registry-sg \
  --description "Security group for MCP registry server"

# Add inbound rules
aws ec2 authorize-security-group-ingress \
  --group-name mcp-registry-sg \
  --protocol tcp --port 22 --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
  --group-name mcp-registry-sg \
  --protocol tcp --port 80 --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
  --group-name mcp-registry-sg \
  --protocol tcp --port 443 --cidr 0.0.0.0/0

# Launch instance
aws ec2 run-instances \
  --image-id ami-0c02fb55b15a0a6e \
  --instance-type t3.micro \
  --key-name your-key-pair \
  --security-groups mcp-registry-sg \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=mcp-registry-server}]'
```

---

## Step 2: Allocate Elastic IP (Recommended)

```bash
# Allocate Elastic IP
aws ec2 allocate-address --domain vpc

# Associate with instance
aws ec2 associate-address \
  --instance-id i-xxxxxxxxxxxxx \
  --allocation-id eipalloc-xxxxxxxxxxxxx
```

**Why:** Prevents IP changes on instance restart.

---

## Step 3: Connect to EC2 Instance

```bash
# SSH into instance
ssh -i your-key.pem ec2-user@<ELASTIC-IP>

# For Ubuntu:
ssh -i your-key.pem ubuntu@<ELASTIC-IP>
```

---

## Step 4: Run Setup Script on EC2

### Upload setup script
```bash
# From your local machine
scp -i your-key.pem ec2-setup.sh configure-nginx.sh ec2-user@<ELASTIC-IP>:~/
```

### Execute on EC2
```bash
# On EC2 instance
chmod +x ec2-setup.sh configure-nginx.sh
sudo bash ec2-setup.sh
```

This will:
- Update system packages
- Install nginx
- Install certbot for SSL
- Create directory structure at `/var/www/mcp-registry/`

---

## Step 5: Upload Registry Files

### From your local machine:

```bash
# Upload registry.json
scp -i your-key.pem registry.json ec2-user@<ELASTIC-IP>:/var/www/mcp-registry/

# Upload JAR files
scp -i your-key.pem MCPServer-1.0.0-runner.jar ec2-user@<ELASTIC-IP>:/var/www/mcp-registry/
scp -i your-key.pem mssql-jdbc-12.4.2.jre11.jar ec2-user@<ELASTIC-IP>:/var/www/mcp-registry/

# Or upload all at once
scp -i your-key.pem registry.json *.jar ec2-user@<ELASTIC-IP>:/var/www/mcp-registry/
```

---

## Step 6: Configure nginx

### On EC2 instance:

```bash
sudo bash configure-nginx.sh
```

This will:
- Configure nginx to serve MCP registry
- Enable CORS headers (required for Amazon Q)
- Set up proper caching policies
- Start nginx service

### Test HTTP access:

```bash
# From EC2 instance
curl http://localhost/registry.json

# From your local machine
curl http://<ELASTIC-IP>/registry.json
```

---

## Step 7: Set Up HTTPS

### Option A: With Domain Name (Recommended)

1. **Point domain to EC2:**
   ```bash
   # In Route53 or your DNS provider
   # Create A record: mcp-registry.yourdomain.com → <ELASTIC-IP>
   ```

2. **Get Let's Encrypt certificate:**
   ```bash
   # On EC2 instance
   sudo certbot --nginx -d mcp-registry.yourdomain.com
   ```

3. **Follow prompts:**
   - Enter email for renewal notifications
   - Agree to terms
   - Choose to redirect HTTP to HTTPS

4. **Test:**
   ```bash
   curl https://mcp-registry.yourdomain.com/registry.json
   ```

### Option B: Without Domain (Self-Signed Certificate)

```bash
# On EC2 instance
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/nginx-selfsigned.key \
  -out /etc/ssl/certs/nginx-selfsigned.crt \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=<ELASTIC-IP>"

# Update nginx configuration
sudo tee /etc/nginx/conf.d/mcp-registry.conf > /dev/null << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name _;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name _;

    ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;

    root /var/www/mcp-registry;
    index registry.json;

    add_header 'Access-Control-Allow-Origin' '*' always;
    add_header 'Access-Control-Allow-Methods' 'GET, OPTIONS' always;
    add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range' always;

    location = /registry.json {
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header 'Access-Control-Allow-Origin' '*' always;
        try_files $uri =404;
    }

    location ~* \.(jar)$ {
        add_header Cache-Control "public, max-age=31536000, immutable";
        add_header 'Access-Control-Allow-Origin' '*' always;
        try_files $uri =404;
    }

    access_log /var/log/nginx/mcp-registry-access.log;
    error_log /var/log/nginx/mcp-registry-error.log;
}
EOF

sudo nginx -t
sudo systemctl restart nginx
```

**Note:** Self-signed certificates will show browser warnings but will work for testing.

---

## Step 8: Test the Registry

### From your local machine:

```bash
# Test registry access
curl https://mcp-registry.yourdomain.com/registry.json

# Test JAR file access
curl -I https://mcp-registry.yourdomain.com/MCPServer-1.0.0-runner.jar

# Test with Amazon Q's user agent
curl -H "User-Agent: AmazonQ/1.0" https://mcp-registry.yourdomain.com/registry.json

# Check CORS headers
curl -I -H "Origin: https://aws.amazon.com" https://mcp-registry.yourdomain.com/registry.json
```

### Expected response:
```json
{
  "servers": [
    {
      "server": {
        "name": "global-jdbc-sql",
        ...
      }
    }
  ]
}
```

---

## Step 9: Configure Amazon Q

### Update Amazon Q Settings:

1. **Open Amazon Q Developer Settings**
2. **Navigate to MCP section**
3. **Add Registry URL:**
   ```
   https://mcp-registry.yourdomain.com/registry.json
   ```
   or
   ```
   https://<ELASTIC-IP>/registry.json
   ```

### Test in Amazon Q:

```
Show available MCP servers
```

Should list `global-jdbc-sql`.

---

## Step 10: Update JAR File URLs in registry.json

### On EC2 instance:

```bash
sudo nano /var/www/mcp-registry/registry.json
```

### Update the `installationInstructions`:

```json
{
  "installationInstructions": "Download JAR files from: https://mcp-registry.yourdomain.com/MCPServer-1.0.0-runner.jar and https://mcp-registry.yourdomain.com/mssql-jdbc-12.4.2.jre11.jar. Place both files in the same directory and ensure Java 21+ is installed."
}
```

---

## Maintenance and Monitoring

### View Access Logs:
```bash
sudo tail -f /var/log/nginx/mcp-registry-access.log
```

### View Error Logs:
```bash
sudo tail -f /var/log/nginx/mcp-registry-error.log
```

### Update Registry:
```bash
# Upload new registry.json
scp -i your-key.pem registry.json ec2-user@<ELASTIC-IP>:/var/www/mcp-registry/

# No restart needed, nginx serves files directly
```

### SSL Certificate Renewal (Let's Encrypt):
```bash
# Automatic renewal is configured by certbot
# Test renewal:
sudo certbot renew --dry-run
```

### Check nginx Status:
```bash
sudo systemctl status nginx
```

---

## Troubleshooting

### Issue: Connection Refused

**Check:**
```bash
sudo systemctl status nginx
sudo netstat -tlnp | grep :443
```

**Fix:**
```bash
sudo systemctl restart nginx
```

### Issue: 404 Not Found

**Check:**
```bash
ls -la /var/www/mcp-registry/
```

**Fix:**
```bash
# Ensure files are in correct location
sudo chown -R nginx:nginx /var/www/mcp-registry/  # Amazon Linux
sudo chown -R www-data:www-data /var/www/mcp-registry/  # Ubuntu
```

### Issue: CORS Errors

**Check headers:**
```bash
curl -I https://mcp-registry.yourdomain.com/registry.json
```

**Should see:**
```
Access-Control-Allow-Origin: *
```

**Fix:**
```bash
# Ensure CORS headers are in nginx config
sudo nano /etc/nginx/conf.d/mcp-registry.conf
# Add: add_header 'Access-Control-Allow-Origin' '*' always;
sudo nginx -t
sudo systemctl restart nginx
```

### Issue: Amazon Q Can't Access Registry

**Debug:**
```bash
# Check from different networks
curl -v https://mcp-registry.yourdomain.com/registry.json

# Check security group allows 443 from 0.0.0.0/0
aws ec2 describe-security-groups --group-ids sg-xxxxx
```

---

## Cost Estimate

- **EC2 t3.micro:** ~$8/month (with 1 year reserved: ~$5/month)
- **Elastic IP:** Free while attached to running instance
- **Data transfer:** First 100 GB/month free
- **SSL certificate:** Free (Let's Encrypt)

**Total: ~$8/month or ~$96/year**

---

## Security Considerations

1. **Restrict SSH access:**
   ```bash
   # Update security group to allow SSH only from your IP
   aws ec2 authorize-security-group-ingress \
     --group-name mcp-registry-sg \
     --protocol tcp --port 22 --cidr YOUR_IP/32
   ```

2. **Enable automatic security updates:**
   ```bash
   # Amazon Linux
   sudo yum install -y yum-cron
   sudo systemctl enable yum-cron
   sudo systemctl start yum-cron

   # Ubuntu
   sudo apt-get install -y unattended-upgrades
   sudo dpkg-reconfigure -plow unattended-upgrades
   ```

3. **Set up CloudWatch monitoring:**
   ```bash
   # Install CloudWatch agent
   wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
   sudo rpm -U ./amazon-cloudwatch-agent.rpm
   ```

---

## Quick Reference

### Important Files:
- Registry: `/var/www/mcp-registry/registry.json`
- nginx config: `/etc/nginx/conf.d/mcp-registry.conf`
- Access logs: `/var/log/nginx/mcp-registry-access.log`
- Error logs: `/var/log/nginx/mcp-registry-error.log`
- SSL cert: `/etc/letsencrypt/live/mcp-registry.yourdomain.com/`

### Important Commands:
```bash
# Restart nginx
sudo systemctl restart nginx

# Test nginx config
sudo nginx -t

# View logs
sudo tail -f /var/log/nginx/mcp-registry-access.log

# Renew SSL
sudo certbot renew

# Update registry
scp -i key.pem registry.json ec2-user@<IP>:/var/www/mcp-registry/
```

---

## Next Steps After Deployment

1. **Test with Amazon Q:** Add registry URL and verify MCP server appears
2. **Update documentation:** Document the final registry URL for your team
3. **Set up monitoring:** Configure CloudWatch alarms for EC2 health
4. **Backup:** Take AMI snapshot of configured EC2 instance
5. **Document for team:** Share installation instructions with Q Developer users

---

**Registry URL:** `https://mcp-registry.yourdomain.com/registry.json`

**Last Updated:** December 25, 2024
