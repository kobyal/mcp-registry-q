# Fix WAF Blocking Amazon Q - Quick Guide

## Issue Identified

**Root Cause:** AWS WAF is blocking Amazon Q's requests to your CloudFront distribution.

**WAF Details:**
- **ARN:** `arn:aws:wafv2:us-east-1:599843985030:global/webacl/FMManagedWebACLV2-Global-Policy-WAF-CloudFront-SBX-1745348315991/de2415af-d505-4033-b813-5462487868ef`
- **Type:** FMM Managed (Firewall Manager Managed)
- **Distribution:** `E389PAO537ZIPN`
- **CloudFront URL:** `https://d16n6l2g9fsqw2.cloudfront.net/registry.json`

## Important Note

This WAF appears to be managed by AWS Firewall Manager (`FMM`), which means it's likely enforced by your organization's security team. You may not be able to modify or remove it without approval.

---

## Solution Options

### Option 1: Request WAF Exception (Recommended for Production)

Contact your security team to whitelist:

**What to request:**
```
Request to whitelist public read access for MCP registry:
- CloudFront Distribution: E389PAO537ZIPN
- URL: https://d16n6l2g9fsqw2.cloudfront.net/registry.json
- Reason: Amazon Q Developer MCP registry endpoint
- Access Pattern: Public GET requests only
- Risk: Low (read-only JSON file, no sensitive data)

Specific exception needed:
- Allow all user agents for GET /registry.json
- Allow all user agents for GET /*.jar
- Keep WAF protection for all other paths
```

**Email template:**
```
Subject: WAF Exception Request for Amazon Q MCP Registry

Hi Security Team,

I need to request a WAF exception for our Amazon Q Developer MCP registry.

CloudFront Distribution: E389PAO537ZIPN
URL: https://d16n6l2g9fsqw2.cloudfront.net/registry.json
Purpose: Public endpoint for Amazon Q Developer to discover MCP servers

The registry contains only:
- registry.json (metadata about available MCP servers)
- JAR files for MCP server installation

No sensitive data is exposed. All requests are read-only (GET).

Can you please create a WAF rule to allow:
1. GET requests to /registry.json from any user agent
2. GET requests to /*.jar from any user agent

This will enable Amazon Q Developer to access our internal MCP server registry.

Thank you!
```

---

### Option 2: Test Without WAF (Temporary)

If you have permissions, temporarily disable WAF for testing:

```bash
# Get current WAF association
aws wafv2 get-web-acl-for-resource \
  --resource-arn "arn:aws:cloudfront::599843985030:distribution/E389PAO537ZIPN"

# Disassociate WAF (requires permissions)
aws wafv2 disassociate-web-acl \
  --resource-arn "arn:aws:cloudfront::599843985030:distribution/E389PAO537ZIPN"

# Test Amazon Q access
# ...

# Re-associate WAF when done
aws wafv2 associate-web-acl \
  --web-acl-arn "arn:aws:wafv2:us-east-1:599843985030:global/webacl/FMManagedWebACLV2-Global-Policy-WAF-CloudFront-SBX-1745348315991/de2415af-d505-4033-b813-5462487868ef" \
  --resource-arn "arn:aws:cloudfront::599843985030:distribution/E389PAO537ZIPN"
```

**Warning:** This may violate security policies. Only do this if you have approval.

---

### Option 3: Add WAF Rule to Allow Amazon Q (If you have WAF permissions)

```bash
# This might not work if WAF is FMM-managed
# But worth trying if you have permissions

# Create IP set for Amazon Q (if we knew their IPs)
aws wafv2 create-ip-set \
  --name AmazonQ-IPs \
  --scope CLOUDFRONT \
  --ip-address-version IPV4 \
  --addresses "0.0.0.0/0"  # Replace with actual Q IP ranges if known

# Create rule to allow registry.json
aws wafv2 update-web-acl \
  --id "de2415af-d505-4033-b813-5462487868ef" \
  --scope CLOUDFRONT \
  --lock-token "..." \
  --rules file://allow-registry-rule.json
```

**allow-registry-rule.json:**
```json
{
  "Name": "AllowMCPRegistry",
  "Priority": 0,
  "Statement": {
    "ByteMatchStatement": {
      "SearchString": "/registry.json",
      "FieldToMatch": {
        "UriPath": {}
      },
      "TextTransformations": [
        {
          "Priority": 0,
          "Type": "NONE"
        }
      ],
      "PositionalConstraint": "CONTAINS"
    }
  },
  "Action": {
    "Allow": {}
  },
  "VisibilityConfig": {
    "SampledRequestsEnabled": true,
    "CloudWatchMetricsEnabled": true,
    "MetricName": "AllowMCPRegistry"
  }
}
```

---

### Option 4: Use Alternative Hosting (FASTEST - Bypass WAF entirely)

Since WAF is blocking CloudFront, use one of these alternatives:

#### A) EC2 with nginx (Recommended - 30 min setup)
Follow: `EC2-IMPLEMENTATION-GUIDE.md`

**Pros:**
- No WAF to deal with
- Full control
- Fast setup

#### B) GitHub Pages (Fastest - 10 min setup)
Follow: `QUICK-ALTERNATIVES.md` - Option 1

**Pros:**
- Free
- No infrastructure
- Works immediately

#### C) Create NEW CloudFront WITHOUT WAF
```bash
# Create new distribution without FMM-managed WAF
aws cloudfront create-distribution \
  --distribution-config file://new-cloudfront-config.json

# Use new distribution for MCP registry only
```

---

## Recommended Action Plan

### For Immediate POC:

1. **Use GitHub Pages** (10 minutes)
   - See `QUICK-ALTERNATIVES.md` Option 1
   - No permissions needed
   - Works immediately

### For Production:

1. **Request WAF exception** from security team
   - Use email template above
   - Wait for approval

2. **While waiting, use EC2** as temporary solution
   - See `EC2-IMPLEMENTATION-GUIDE.md`
   - Can be done in parallel
   - Migration path: Q users just change registry URL

---

## Testing After Fix

```bash
# Run diagnostics again
bash diagnose-cloudfront.sh

# Test with Amazon Q
# In Q Developer settings, add registry URL:
https://d16n6l2g9fsqw2.cloudfront.net/registry.json

# Or use alternative URL from EC2/GitHub
```

---

## WAF Logs Analysis (If you have access)

Check WAF logs to see what's being blocked:

```bash
# Query CloudWatch Logs Insights
# Log group: aws-waf-logs-cloudfront-E389PAO537ZIPN

# Sample query:
fields @timestamp, httpRequest.clientIp, httpRequest.uri, action
| filter httpRequest.uri like /registry.json/
| filter action = "BLOCK"
| sort @timestamp desc
| limit 100
```

This will show you:
- Which IPs are being blocked
- What user agents Q is using
- Why the request is blocked

---

## Quick Decision Tree

```
Can you modify WAF?
├─ YES → Add rule to allow /registry.json
└─ NO
   ├─ Can you wait for security approval?
   │  ├─ YES → Request WAF exception + Use EC2 temporarily
   │  └─ NO → Use GitHub Pages or EC2 permanently
   └─ Need POC NOW?
      └─ Use GitHub Pages (10 min setup)
```

---

## My Recommendation

**For immediate POC delivery:**
1. Use GitHub Pages NOW (takes 10 minutes)
2. Document and demo with GitHub URL
3. Request WAF exception in parallel
4. Switch to CloudFront after approval

**GitHub Pages URL will be:**
```
https://YOUR_GITHUB_USERNAME.github.io/mcp-registry/registry.json
```

**Update Amazon Q settings with this URL, and you're done!**

---

## Files Created for You

1. `EC2-IMPLEMENTATION-GUIDE.md` - Full EC2 setup with nginx
2. `QUICK-ALTERNATIVES.md` - GitHub Pages, Netlify, etc.
3. `diagnose-cloudfront.sh` - Diagnostic script (already ran)
4. `ec2-setup.sh` - Automated EC2 setup script
5. `configure-nginx.sh` - nginx configuration script
6. `mcp-registry-poc-progress.md` - Full conversation and context

---

**Last Updated:** December 25, 2024
