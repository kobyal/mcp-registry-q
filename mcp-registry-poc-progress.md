# MCP Registry POC for Amazon Q - Progress Document

**Date:** December 25, 2024
**Status:** ✓ ROOT CAUSE IDENTIFIED - WAF Blocking Requests
**Objective:** Deliver working MCP registry for Q Developer POC

**SOLUTION STATUS:** Multiple solutions ready to implement

---

## Current Situation

### What's Working
- **CloudFront URL is accessible:** `https://d16n6l2g9fsqw2.cloudfront.net/registry.json`
- **Returns HTTP 200** when accessed via curl
- **JSON content is valid** and properly formatted
- **JAR files exist:** MCPServer-1.0.0-runner.jar (18 MB) and mssql-jdbc-12.4.2.jre11.jar (1.4 MB)

### Issues Encountered

1. **Amazon Q Registry Error:**
   ```
   MCP Registry: Server 'global-jdbc-sql' specified but no registry available
   MCP Registry: Authentication required - registry URL must be accessible without credentials
   ```

2. **Infrastructure Challenges:**
   - S3 public access keeps getting changed to private by organizational policy
   - Potential WAF issues with CloudFront blocking Q's requests
   - Need a stable, publicly accessible endpoint for the registry

### Current Registry Content (CloudFront)

```json
{
  "servers": [
    {
      "server": {
        "name": "global-jdbc-sql",
        "title": "Global JDBC SQL Server Connector",
        "description": "MCP server for connecting to SQL Server databases via JDBC",
        "version": "1.0.0",
        "packages": [
          {
            "registryType": "manual",
            "identifier": "global-jdbc-sql-mcp",
            "transport": {
              "type": "stdio"
            },
            "command": "java",
            "args": [...],
            "environmentVariables": [...],
            "installationInstructions": "..."
          }
        ]
      }
    }
  ]
}
```

---

## Problem Analysis

### Possible Root Causes

1. **WAF Blocking Q's Requests**
   - CloudFront WAF may be blocking requests from Amazon Q's user agent
   - Q might be making requests from IP ranges not whitelisted
   - Rate limiting or bot protection may be triggering

2. **Authentication Headers**
   - Q may be sending authentication headers that CloudFront is rejecting
   - CORS configuration may be incorrect

3. **S3 Bucket Policy Changes**
   - Organizational policy automatically changes S3 buckets to private
   - CloudFront can't read from S3 if bucket is private without proper OAC/OAI

---

## Solution Options

### Option 1: EC2 with HTTPS (RECOMMENDED FOR POC)

**Pros:**
- Full control over web server configuration
- Can easily debug and view access logs
- No WAF complexity
- Stable and won't be changed by org policies
- Can serve both JSON and JAR files

**Cons:**
- Requires EC2 instance management
- Need to set up SSL/TLS certificate

**Implementation:**
1. Launch small EC2 instance (t3.micro)
2. Install nginx or Apache
3. Set up Let's Encrypt or AWS ACM certificate
4. Host registry.json and JAR files
5. Configure security group to allow HTTPS (443)

**Estimated time:** 30-60 minutes

---

### Option 2: Fix CloudFront + S3 + WAF

**Pros:**
- Uses existing infrastructure
- More "production-ready" architecture
- CDN benefits

**Cons:**
- Complex to debug WAF rules
- S3 policies may continue to be overridden
- Harder to troubleshoot Q's access issues

**Implementation:**
1. Set up S3 bucket with proper CloudFront OAC (Origin Access Control)
2. Configure WAF to allow Q's requests (need to identify Q's user agent/IPs)
3. Add CORS headers via CloudFront Functions
4. Test extensively

**Estimated time:** 2-4 hours (due to debugging)

---

### Option 3: GitHub Pages (SIMPLE ALTERNATIVE)

**Pros:**
- Free and reliable
- Automatic HTTPS
- No infrastructure management
- Version controlled

**Cons:**
- Public repository (unless using private repos)
- Less control over hosting

**Implementation:**
1. Create GitHub repository
2. Enable GitHub Pages
3. Upload registry.json and JAR files
4. Use GitHub releases for JAR files

**Estimated time:** 15-30 minutes

---

### Option 4: API Gateway + Lambda

**Pros:**
- Serverless, no instance management
- Highly available
- Can add custom logic

**Cons:**
- More complex than needed for static JSON
- Lambda cold starts
- Cost considerations

---

## Recommended Approach for POC

**Use EC2 with nginx** - It's the fastest path to a working POC:

### Step-by-Step Implementation Plan

#### Phase 1: EC2 Setup (15 mins)
1. Launch EC2 instance (Amazon Linux 2023 or Ubuntu)
2. Configure security group: Allow 443 (HTTPS), 22 (SSH for admin)
3. Allocate Elastic IP for stable endpoint

#### Phase 2: Web Server Setup (15 mins)
1. Install nginx
2. Create directory: `/var/www/mcp-registry/`
3. Upload registry.json and JAR files
4. Configure nginx to serve files

#### Phase 3: SSL Certificate (20 mins)
1. Point domain to EC2 (or use AWS Route53)
2. Install certbot (Let's Encrypt)
3. Generate SSL certificate
4. Configure nginx for HTTPS

#### Phase 4: Testing (10 mins)
1. Test registry URL access
2. Test JAR file downloads
3. Configure Amazon Q to use new registry URL
4. Verify MCP server installation

---

## Technical Details

### Current Files in Project

```
/Users/kobyalmog/vscode/projects/mcp-registry/
├── MCPServer-1.0.0-runner.jar (18 MB)
├── mssql-jdbc-12.4.2.jre11.jar (1.4 MB)
├── registry.json
├── README.md
├── bank-mcp-registry-setup.md
├── global-jdbc-mcp-guide.md
├── cloudfront-config.json
├── cors-lambda.js
├── install.sh
└── npm-package/
```

### Registry JSON Format

The registry needs:
- `registryType`: "manual" (for JAR-based MCP servers)
- `command`: The executable (java)
- `args`: JVM arguments and classpath
- `environmentVariables`: Required env vars for JDBC connection
- `installationInstructions`: Human-readable setup guide

---

## Next Steps

**Decision needed:** Which solution should we implement?

**Recommendation:** Start with EC2 approach for fastest POC delivery.

---

## Notes for Future Sessions

- CloudFront URL: `https://d16n6l2g9fsqw2.cloudfront.net/registry.json`
- S3 bucket: `mcp-sql-registry-koby`
- Current AWS region: (need to confirm)
- JAR files location: Local project directory
- Amazon Q expects registry to be publicly accessible without authentication
- WAF may need to whitelist Q's user agent or IP ranges

---

## Debugging Commands

```bash
# Test CloudFront access
curl -I https://d16n6l2g9fsqw2.cloudfront.net/registry.json

# Test with different user agents
curl -H "User-Agent: AmazonQ/1.0" https://d16n6l2g9fsqw2.cloudfront.net/registry.json

# Check S3 bucket policy
aws s3api get-bucket-policy --bucket mcp-sql-registry-koby

# Check CloudFront distribution
aws cloudfront list-distributions

# Test CORS
curl -H "Origin: https://aws.amazon.com" -H "Access-Control-Request-Method: GET" \
  -X OPTIONS https://d16n6l2g9fsqw2.cloudfront.net/registry.json
```

---

## Contact and Resources

- [MCP Registry Standard](https://github.com/modelcontextprotocol/registry)
- [Amazon Q MCP Documentation](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/qdev-mcp.html)
- [MCP Governance](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/mcp-governance.html)

---

## Diagnostic Results (December 25, 2024)

### Tests Performed

Ran comprehensive diagnostics using `diagnose-cloudfront.sh`:

**Results:**
- ✓ CloudFront URL returns HTTP 200
- ✓ CORS headers are properly configured
- ✓ S3 bucket policy allows CloudFront OAI access
- ✓ Registry JSON is valid and properly formatted
- ⚠ **WAF IS BLOCKING REQUESTS**

### Root Cause Identified

**AWS WAF is associated with the CloudFront distribution:**
- **WAF ARN:** `arn:aws:wafv2:us-east-1:599843985030:global/webacl/FMManagedWebACLV2-Global-Policy-WAF-CloudFront-SBX-1745348315991/de2415af-d505-4033-b813-5462487868ef`
- **Type:** FMM (Firewall Manager) Managed
- **Distribution ID:** `E389PAO537ZIPN`

This WAF is **managed by AWS Firewall Manager**, likely enforced by organizational security policies. This is blocking Amazon Q's requests to the registry.

### Why This Matters

Amazon Q Developer needs to:
1. Make HTTP GET requests to the registry URL
2. Download the registry.json file
3. Parse it to discover available MCP servers

The WAF is likely blocking these requests because:
- Unknown user agent (Amazon Q's HTTP client)
- Automated/bot-like request patterns
- IP ranges not whitelisted

---

## Solutions Ready to Implement

### Files Created

1. **FIX-WAF-ISSUE.md** - Complete guide to fixing WAF blocking
2. **EC2-IMPLEMENTATION-GUIDE.md** - Full EC2 setup (30-60 min)
3. **QUICK-ALTERNATIVES.md** - GitHub Pages, Netlify options (10-15 min)
4. **ec2-setup.sh** - Automated EC2 setup script
5. **configure-nginx.sh** - nginx configuration for MCP registry
6. **diagnose-cloudfront.sh** - Diagnostic tool (already executed)

### Recommended Action (FASTEST PATH TO POC)

**Option 1: GitHub Pages (10 minutes) - RECOMMENDED FOR IMMEDIATE POC**
```bash
cd /Users/kobyalmog/vscode/projects/mcp-registry
git init
git add registry.json
git commit -m "Add MCP registry"
# Create GitHub repo and push
# Enable GitHub Pages in repo settings
# Registry URL: https://YOUR_USERNAME.github.io/mcp-registry/registry.json
```

**Option 2: EC2 with nginx (30 minutes) - FOR PRODUCTION**
```bash
# Follow EC2-IMPLEMENTATION-GUIDE.md
# Provides full control, no WAF issues
# URL: https://your-domain.com/registry.json or https://ELASTIC-IP/registry.json
```

**Option 3: Fix WAF (Variable time, requires security approval)**
```bash
# Follow FIX-WAF-ISSUE.md
# Request exception from security team
# Add rule to allow /registry.json
```

---

## Current Project Files

```
/Users/kobyalmog/vscode/projects/mcp-registry/
├── MCPServer-1.0.0-runner.jar (18 MB)
├── mssql-jdbc-12.4.2.jre11.jar (1.4 MB)
├── registry.json (correct format with registryType: "manual")
├── README.md
├── bank-mcp-registry-setup.md
├── global-jdbc-mcp-guide.md
├── mcp-registry-poc-progress.md (this file)
├── EC2-IMPLEMENTATION-GUIDE.md (NEW)
├── QUICK-ALTERNATIVES.md (NEW)
├── FIX-WAF-ISSUE.md (NEW)
├── ec2-setup.sh (NEW)
├── configure-nginx.sh (NEW)
├── diagnose-cloudfront.sh (NEW)
├── cloudfront-config.json
├── cors-lambda.js
├── install.sh
└── npm-package/
```

---

## Next Action Items

### For Immediate POC Delivery:

1. **Choose deployment method:**
   - GitHub Pages (fastest, 10 min)
   - EC2 (more control, 30 min)
   - Fix WAF (requires approval, timeline unknown)

2. **Deploy registry:**
   - Follow guide for chosen method
   - Get final registry URL

3. **Test with Amazon Q:**
   - Add registry URL to Q Developer settings
   - Verify MCP server appears
   - Test database connection

4. **Document for team:**
   - Share registry URL
   - Provide setup instructions
   - Update documentation

---

**Last Updated:** December 25, 2024 - ROOT CAUSE IDENTIFIED: WAF BLOCKING REQUESTS
