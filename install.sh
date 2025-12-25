#!/bin/bash

# MCP SQL Server Installation Script
# This script downloads and configures the MCP SQL server for Amazon Q Developer

set -e

echo "🚀 Installing MCP SQL Server..."

# Create MCP directory
MCP_DIR="$HOME/.mcp/global-jdbc-sql"
mkdir -p "$MCP_DIR"

echo "📁 Created directory: $MCP_DIR"

# Download JAR files
echo "⬇️  Downloading MCP Server JAR..."
curl -L -o "$MCP_DIR/MCPServer-1.0.0-runner.jar" \
  "https://mcp-sql-registry-koby.s3.amazonaws.com/MCPServer-1.0.0-runner.jar"

echo "⬇️  Downloading SQL Server JDBC Driver..."
curl -L -o "$MCP_DIR/mssql-jdbc-12.4.2.jre11.jar" \
  "https://mcp-sql-registry-koby.s3.amazonaws.com/mssql-jdbc-12.4.2.jre11.jar"

# Check Java version
echo "☕ Checking Java version..."
if ! command -v java &> /dev/null; then
    echo "❌ Java not found. Please install Java 21 or higher."
    exit 1
fi

JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
if [ "$JAVA_VERSION" -lt 21 ]; then
    echo "❌ Java 21 or higher required. Found Java $JAVA_VERSION"
    exit 1
fi

echo "✅ Java $JAVA_VERSION found"

# Create sample configuration
cat > "$MCP_DIR/sample-config.json" << 'EOF'
{
  "mcpServers": {
    "global-jdbc-sql": {
      "command": "java",
      "args": [
        "-Xms512m",
        "-Xmx2g",
        "-XX:+UseG1GC",
        "-XX:MaxGCPauseMillis=200",
        "-Dfile.encoding=UTF-8",
        "-Dsun.stdout.encoding=UTF-8",
        "-Dsun.stderr.encoding=UTF-8",
        "-cp",
        "~/.mcp/global-jdbc-sql/MCPServer-1.0.0-runner.jar:~/.mcp/global-jdbc-sql/mssql-jdbc-12.4.2.jre11.jar",
        "io.quarkus.runner.GeneratedMain"
      ],
      "env": {
        "jdbc.url": "jdbc:sqlserver://YOUR_HOST:1433;database=YOUR_DB;trustServerCertificate=true;encrypt=false",
        "jdbc.user": "YOUR_USERNAME",
        "jdbc.password": "YOUR_PASSWORD"
      },
      "timeout": 60000,
      "disabled": false
    }
  }
}
EOF

echo "📝 Created sample configuration at: $MCP_DIR/sample-config.json"

echo ""
echo "✅ Installation complete!"
echo ""
echo "📋 Next steps:"
echo "1. Edit the configuration file: $MCP_DIR/sample-config.json"
echo "2. Update jdbc.url, jdbc.user, and jdbc.password with your database details"
echo "3. Add the MCP server to your Amazon Q Developer configuration"
echo "4. Registry URL: https://mcp-sql-registry-koby.s3.amazonaws.com/registry.json"
echo ""
echo "🔗 For more information, visit:"
echo "   https://mcp-sql-registry-koby.s3.amazonaws.com/README.md"
