# Quick Alternative Solutions for MCP Registry

If EC2 seems like overkill, here are simpler alternatives to get your MCP registry working ASAP.

---

## Option 1: GitHub Pages (Fastest - 10 minutes)

### Pros:
- Free
- Automatic HTTPS
- No server management
- Version controlled

### Steps:

1. **Create GitHub repo:**
   ```bash
   cd /Users/kobyalmog/vscode/projects/mcp-registry
   git init
   git add registry.json
   git commit -m "Add MCP registry"
   git branch -M main
   ```

2. **Push to GitHub:**
   ```bash
   # Create repo on GitHub first, then:
   git remote add origin https://github.com/YOUR_USERNAME/mcp-registry.git
   git push -u origin main
   ```

3. **Enable GitHub Pages:**
   - Go to repo Settings → Pages
   - Source: Deploy from main branch
   - Save

4. **Your registry URL will be:**
   ```
   https://YOUR_USERNAME.github.io/mcp-registry/registry.json
   ```

5. **Upload JAR files to GitHub Releases:**
   - Create a new release (e.g., v1.0.0)
   - Upload MCPServer-1.0.0-runner.jar
   - Upload mssql-jdbc-12.4.2.jre11.jar
   - Get download URLs and update registry.json

**Time:** 10 minutes
**Cost:** $0

---

## Option 2: Fix CloudFront WAF (Recommended if you want to keep current setup)

Your CloudFront is already working! The issue is likely Q can't authenticate or WAF is blocking it.

### Quick Fix:

1. **Check S3 bucket policy:**
   ```bash
   aws s3api get-bucket-policy --bucket mcp-sql-registry-koby
   ```

2. **Set up CloudFront Origin Access Control (OAC):**
   ```bash
   # Create OAC
   aws cloudfront create-origin-access-control \
     --origin-access-control-config \
     "Name=mcp-registry-oac,\
     Description=OAC for MCP registry,\
     SigningProtocol=sigv4,\
     SigningBehavior=always,\
     OriginAccessControlOriginType=s3"
   ```

3. **Update S3 bucket policy to allow CloudFront OAC:**
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "AllowCloudFrontServicePrincipal",
         "Effect": "Allow",
         "Principal": {
           "Service": "cloudfront.amazonaws.com"
         },
         "Action": "s3:GetObject",
         "Resource": "arn:aws:s3:::mcp-sql-registry-koby/*",
         "Condition": {
           "StringEquals": {
             "AWS:SourceArn": "arn:aws:cloudfront::YOUR_ACCOUNT_ID:distribution/YOUR_DISTRIBUTION_ID"
           }
         }
       }
     ]
   }
   ```

4. **Update CloudFront distribution to use OAC:**
   ```bash
   aws cloudfront update-distribution \
     --id YOUR_DISTRIBUTION_ID \
     --origin-access-control-id YOUR_OAC_ID
   ```

5. **Disable WAF or whitelist common user agents:**
   ```bash
   # Option A: Temporarily disable WAF
   aws wafv2 disassociate-web-acl \
     --resource-arn arn:aws:cloudfront::ACCOUNT:distribution/DIST_ID

   # Option B: Add rule to allow all GET requests to /registry.json
   ```

**Time:** 30 minutes
**Cost:** $0 (existing infrastructure)

---

## Option 3: Simple Python HTTP Server (Testing Only)

For quick local/network testing:

```bash
cd /Users/kobyalmog/vscode/projects/mcp-registry

# Create simple CORS-enabled server
cat > server.py << 'EOF'
from http.server import HTTPServer, SimpleHTTPRequestHandler
import ssl

class CORSRequestHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', '*')
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

# Run server
httpd = HTTPServer(('0.0.0.0', 8443), CORSRequestHandler)
httpd.socket = ssl.wrap_socket(httpd.socket,
    certfile='./server.pem',
    server_side=True)
print('Server running on https://0.0.0.0:8443')
httpd.serve_forever()
EOF

# Generate self-signed cert
openssl req -x509 -newkey rsa:4096 -nodes -out server.pem -keyout server.pem -days 365

# Run server
python3 server.py
```

**Access at:** `https://YOUR_IP:8443/registry.json`

**Time:** 5 minutes
**Cost:** $0
**Note:** Only for testing, not production

---

## Option 4: AWS S3 + CloudFront with Proper Policies

Since your org keeps changing S3 to private, let's work WITH that:

### Script to set up proper S3 + CloudFront:

```bash
#!/bin/bash
BUCKET_NAME="mcp-sql-registry-koby"
REGION="us-east-1"

# 1. Keep bucket private (org policy compliant)
aws s3api put-public-access-block \
  --bucket $BUCKET_NAME \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# 2. Upload files
aws s3 cp registry.json s3://$BUCKET_NAME/ --content-type "application/json"
aws s3 cp MCPServer-1.0.0-runner.jar s3://$BUCKET_NAME/
aws s3 cp mssql-jdbc-12.4.2.jre11.jar s3://$BUCKET_NAME/

# 3. Create CloudFront Origin Access Control
OAC_ID=$(aws cloudfront create-origin-access-control \
  --origin-access-control-config \
  "Name=mcp-registry-oac,\
  Description=OAC for MCP registry,\
  SigningProtocol=sigv4,\
  SigningBehavior=always,\
  OriginAccessControlOriginType=s3" \
  --query 'OriginAccessControl.Id' --output text)

echo "Created OAC: $OAC_ID"

# 4. Get CloudFront distribution ID
DIST_ID=$(aws cloudfront list-distributions \
  --query "DistributionList.Items[?Origins.Items[?DomainName=='$BUCKET_NAME.s3.amazonaws.com']].Id" \
  --output text)

echo "Distribution ID: $DIST_ID"

# 5. Get AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# 6. Update S3 bucket policy
cat > /tmp/bucket-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFrontServicePrincipal",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::$BUCKET_NAME/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "arn:aws:cloudfront::$ACCOUNT_ID:distribution/$DIST_ID"
        }
      }
    }
  ]
}
EOF

aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file:///tmp/bucket-policy.json

echo "Setup complete! Test with:"
echo "curl https://d16n6l2g9fsqw2.cloudfront.net/registry.json"
```

**Time:** 20 minutes
**Cost:** $0 (existing infrastructure)

---

## Option 5: Netlify (Simplest Hosted Solution)

1. **Install Netlify CLI:**
   ```bash
   npm install -g netlify-cli
   ```

2. **Deploy:**
   ```bash
   cd /Users/kobyalmog/vscode/projects/mcp-registry
   netlify deploy --prod
   ```

3. **Follow prompts:**
   - Create new site
   - Deploy directory: `.` (current)

4. **Get URL:**
   ```
   https://your-site.netlify.app/registry.json
   ```

**Time:** 5 minutes
**Cost:** $0 (Free tier)

---

## Recommendation

**For POC delivery urgency:**

1. **Try Option 2 first** (Fix CloudFront) - You already have it set up
2. **If that fails, use Option 1** (GitHub Pages) - Fastest alternative
3. **For production, use EC2** (from main guide) - Most control and reliability

---

## Testing Your Registry

Whichever option you choose, test with:

```bash
# Basic access
curl https://YOUR_REGISTRY_URL/registry.json

# With Amazon Q user agent
curl -H "User-Agent: AmazonQ/1.0" https://YOUR_REGISTRY_URL/registry.json

# Check CORS
curl -I -H "Origin: https://aws.amazon.com" https://YOUR_REGISTRY_URL/registry.json

# Verify JSON is valid
curl https://YOUR_REGISTRY_URL/registry.json | jq .
```

---

**Last Updated:** December 25, 2024
