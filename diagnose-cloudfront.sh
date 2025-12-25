#!/bin/bash
# CloudFront and WAF Diagnostic Script
# Helps identify why Amazon Q can't access the registry

echo "========================================="
echo "MCP Registry CloudFront Diagnostics"
echo "========================================="
echo ""

CLOUDFRONT_URL="https://d16n6l2g9fsqw2.cloudfront.net/registry.json"
BUCKET_NAME="mcp-sql-registry-koby"

echo "1. Testing CloudFront access..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" $CLOUDFRONT_URL)
echo "   HTTP Status: $HTTP_CODE"

if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✓ CloudFront is accessible"
else
    echo "   ✗ CloudFront returned error: $HTTP_CODE"
fi

echo ""
echo "2. Testing with different User-Agent strings..."

# Test with standard browser
echo "   Standard browser:"
curl -s -o /dev/null -w "   HTTP %{http_code}\n" -H "User-Agent: Mozilla/5.0" $CLOUDFRONT_URL

# Test with Amazon Q (guessed)
echo "   AmazonQ user agent:"
curl -s -o /dev/null -w "   HTTP %{http_code}\n" -H "User-Agent: AmazonQ/1.0" $CLOUDFRONT_URL

# Test with AWS SDK
echo "   AWS SDK user agent:"
curl -s -o /dev/null -w "   HTTP %{http_code}\n" -H "User-Agent: aws-sdk-js/3.0.0" $CLOUDFRONT_URL

# Test with generic
echo "   Generic user agent:"
curl -s -o /dev/null -w "   HTTP %{http_code}\n" -H "User-Agent: curl/7.0" $CLOUDFRONT_URL

echo ""
echo "3. Checking CORS headers..."
CORS_HEADERS=$(curl -s -I -H "Origin: https://aws.amazon.com" $CLOUDFRONT_URL | grep -i "access-control")
if [ -z "$CORS_HEADERS" ]; then
    echo "   ✗ No CORS headers found"
    echo "   This may prevent Amazon Q from accessing the registry"
else
    echo "   ✓ CORS headers present:"
    echo "$CORS_HEADERS" | sed 's/^/     /'
fi

echo ""
echo "4. Checking S3 bucket configuration..."

# Check if AWS CLI is available
if ! command -v aws &> /dev/null; then
    echo "   ⚠ AWS CLI not installed, skipping bucket checks"
else
    # Check bucket public access block
    echo "   Public Access Block settings:"
    aws s3api get-public-access-block --bucket $BUCKET_NAME 2>/dev/null | sed 's/^/     /'

    # Check bucket policy
    echo ""
    echo "   Bucket Policy:"
    aws s3api get-bucket-policy --bucket $BUCKET_NAME 2>/dev/null | sed 's/^/     /'
    if [ $? -ne 0 ]; then
        echo "     ✗ No bucket policy found or access denied"
    fi
fi

echo ""
echo "5. Testing CloudFront distribution..."

if command -v aws &> /dev/null; then
    DIST_ID=$(aws cloudfront list-distributions --query "DistributionList.Items[?Origins.Items[?contains(DomainName, '$BUCKET_NAME')]].Id" --output text 2>/dev/null)

    if [ -n "$DIST_ID" ]; then
        echo "   Distribution ID: $DIST_ID"

        # Check if WAF is associated
        echo "   Checking WAF association..."
        WAF_ARN=$(aws cloudfront get-distribution --id $DIST_ID --query "Distribution.DistributionConfig.WebACLId" --output text 2>/dev/null)

        if [ -n "$WAF_ARN" ] && [ "$WAF_ARN" != "None" ]; then
            echo "   ⚠ WAF is associated: $WAF_ARN"
            echo "   This might be blocking Amazon Q's requests"
        else
            echo "   ✓ No WAF associated"
        fi

        # Check Origin Access Control
        echo ""
        echo "   Origin Access Control:"
        aws cloudfront get-distribution --id $DIST_ID \
            --query "Distribution.DistributionConfig.Origins.Items[0].OriginAccessControlId" \
            --output text 2>/dev/null | sed 's/^/     /'
    else
        echo "   ✗ Could not find CloudFront distribution"
    fi
else
    echo "   ⚠ AWS CLI not available, skipping distribution checks"
fi

echo ""
echo "6. Content verification..."
echo "   First 200 characters of response:"
curl -s $CLOUDFRONT_URL | head -c 200
echo ""
echo "   ..."

echo ""
echo "========================================="
echo "Summary"
echo "========================================="

if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ Registry is publicly accessible"

    if [ -z "$CORS_HEADERS" ]; then
        echo "✗ MISSING: CORS headers - This is likely the issue!"
        echo ""
        echo "RECOMMENDATION: Add CORS headers via CloudFront function"
        echo ""
        echo "Quick fix:"
        echo "  1. Create CloudFront Function with CORS headers"
        echo "  2. Associate with distribution"
        echo "  3. See cors-lambda.js for example code"
    else
        echo "✓ CORS headers present"

        if [ -n "$WAF_ARN" ] && [ "$WAF_ARN" != "None" ]; then
            echo "⚠ WAF is enabled - might be blocking Q's requests"
            echo ""
            echo "RECOMMENDATION: Check WAF logs or temporarily disable"
        else
            echo ""
            echo "Everything looks good! The issue might be:"
            echo "  1. Amazon Q can't reach the URL (firewall/proxy)"
            echo "  2. Q is using a different user agent that's blocked"
            echo "  3. Q expects a specific registry format"
            echo ""
            echo "Try configuring Q to use this URL:"
            echo "  $CLOUDFRONT_URL"
        fi
    fi
else
    echo "✗ Registry is not accessible (HTTP $HTTP_CODE)"
    echo ""
    echo "RECOMMENDATION: Check CloudFront and S3 bucket permissions"
fi

echo ""
echo "========================================="
