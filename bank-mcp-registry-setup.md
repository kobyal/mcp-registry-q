# Private MCP Registry Setup Guide for Banking Environment

## Overview

This guide sets up a private Model Context Protocol (MCP) registry for air-gapped banking environments using Amazon Q Developer. The registry will be hosted internally and contain vetted MCP servers for database connectivity.

## Prerequisites

- Amazon Q Developer Pro with IAM Identity Center
- Internal web server with HTTPS capability (Jenkins, IIS, Apache, etc.)
- Java 21+ installed on client workstations
- SQL Server JDBC drivers
- Network access between Q clients and internal registry server

## Architecture

```
[Q Developer Client] → [Internal HTTPS Registry] → [MCP Server JAR + JDBC Drivers]
                                ↓
                        [SQL Server Database]
```

## Step 1: Prepare MCP Server Files

### 1.1 Create Directory Structure
```bash
# On your file server or shared location
mkdir /shared/mcp-servers/global-jdbc
cd /shared/mcp-servers/global-jdbc
```

### 1.2 Copy Required Files
```bash
# Copy your MCP server JAR
cp MCPServer-1.0.0-runner.jar /shared/mcp-servers/global-jdbc/

# Copy SQL Server JDBC driver
cp mssql-jdbc-12.4.2.jre11.jar /shared/mcp-servers/global-jdbc/
```

### 1.3 Verify Java Installation
```bash
# Check Java version on client machines
java -version
# Should show Java 21 or higher

# Find Java path (Windows)
where java
# Example: C:\Program Files\Java\jdk-21\bin\java.exe
```

## Step 2: Create Private MCP Registry

### 2.1 Registry JSON File
Create `mcp-registry.json`:

```json
{
  "servers": [
    {
      "server": {
        "name": "bank-global-jdbc",
        "title": "Bank JDBC Database Connector",
        "description": "Internal MCP server for secure database connectivity to bank SQL Server instances",
        "version": "1.0.0",
        "packages": [
          {
            "registryType": "file",
            "identifier": "file:///shared/mcp-servers/global-jdbc/MCPServer-1.0.0-runner.jar",
            "transport": {
              "type": "stdio"
            },
            "runtimeArguments": [
              {
                "type": "positional",
                "value": "java"
              },
              {
                "type": "positional",
                "value": "-Xms512m"
              },
              {
                "type": "positional",
                "value": "-Xmx2g"
              },
              {
                "type": "positional",
                "value": "-XX:+UseG1GC"
              },
              {
                "type": "positional",
                "value": "-XX:MaxGCPauseMillis=200"
              },
              {
                "type": "positional",
                "value": "-Dfile.encoding=UTF-8"
              },
              {
                "type": "positional",
                "value": "-cp"
              },
              {
                "type": "positional",
                "value": "/shared/mcp-servers/global-jdbc/MCPServer-1.0.0-runner.jar:/shared/mcp-servers/global-jdbc/mssql-jdbc-12.4.2.jre11.jar"
              },
              {
                "type": "positional",
                "value": "io.quarkus.runner.GeneratedMain"
              }
            ],
            "environmentVariables": [
              {
                "name": "jdbc.url",
                "value": "REQUIRED"
              },
              {
                "name": "jdbc.user",
                "value": "REQUIRED"
              },
              {
                "name": "jdbc.password",
                "value": "REQUIRED"
              }
            ]
          }
        ]
      }
    }
  ]
}
```

### 2.2 Host Registry File

**Option A: Jenkins (Recommended)**
```bash
# Place in Jenkins workspace accessible via HTTPS
cp mcp-registry.json /var/jenkins_home/workspace/mcp-registry/
# Access via: https://jenkins.bank.internal/job/mcp-registry/ws/mcp-registry.json
```

**Option B: IIS/Apache Web Server**
```bash
# Place in web root
cp mcp-registry.json /var/www/html/mcp/
# Access via: https://webserver.bank.internal/mcp/mcp-registry.json
```

**Option C: Bitbucket Server**
```bash
# Create repository and serve raw file
# Access via: https://bitbucket.bank.internal/projects/MCP/repos/registry/raw/mcp-registry.json
```

## Step 3: Configure Q Developer Profile (Administrator)

### 3.1 Access Q Developer Settings
1. Open **Kiro Console** (AWS Console)
2. Navigate to **Settings**
3. Select **Q Developer** tab

### 3.2 Configure MCP Registry
1. Ensure **Model Context Protocol (MCP)** is **On**
2. Click **Edit** next to **MCP Registry URL**
3. Enter your internal registry URL:
   ```
   https://jenkins.bank.internal/job/mcp-registry/ws/mcp-registry.json
   ```
4. Click **Save**

## Step 4: Client Configuration

### 4.1 Local MCP Configuration
Each user needs to configure their local Q Developer:

**File Location:** `~/.aws/amazonq/agents/default.json`

```json
{
  "mcpServers": {
    "bank-global-jdbc": {
      "command": "java",
      "args": [
        "-Xms512m",
        "-Xmx2g",
        "-XX:+UseG1GC",
        "-XX:MaxGCPauseMillis=200",
        "-Dfile.encoding=UTF-8",
        "-cp",
        "/shared/mcp-servers/global-jdbc/MCPServer-1.0.0-runner.jar:/shared/mcp-servers/global-jdbc/mssql-jdbc-12.4.2.jre11.jar",
        "io.quarkus.runner.GeneratedMain"
      ],
      "env": {
        "jdbc.url": "jdbc:sqlserver://SQLSERVER.bank.internal:1433;database=testdb;trustServerCertificate=true;encrypt=false",
        "jdbc.user": "bank_user",
        "jdbc.password": "secure_password"
      },
      "timeout": 60000,
      "disabled": false
    }
  }
}
```

## Step 5: Testing and Validation

### 5.1 Test Registry Access
```bash
# Verify registry is accessible
curl -k https://jenkins.bank.internal/job/mcp-registry/ws/mcp-registry.json
```

### 5.2 Test MCP Server
1. Open Q Developer CLI
2. Run: `/tools`
3. Verify `bank-global-jdbc` tools are listed
4. Test database connection:
   ```
   Show me the schemas in the database
   ```

### 5.3 Validate Database Connectivity
```sql
-- Test query through Q Developer
SELECT CURRENT_TIMESTAMP, @@VERSION
```

## Common Pitfalls and Solutions

### ⚠️ Path Issues
**Problem:** File paths not accessible from client machines
**Solution:** Use UNC paths on Windows: `\\fileserver\shared\mcp-servers\...`

### ⚠️ SSL Certificate Issues
**Problem:** HTTPS certificate not trusted
**Solution:** 
- Use internal CA certificates
- Or configure Q Developer to accept self-signed certificates (dev only)

### ⚠️ Java Classpath
**Problem:** JDBC driver not found
**Solution:** Ensure both JAR files are in classpath with correct separator:
- Windows: `;` (semicolon)
- Linux: `:` (colon)

### ⚠️ Database Connection
**Problem:** SSL/TLS connection failures
**Solution:** Use connection string with:
```
trustServerCertificate=true;encrypt=false
```

### ⚠️ Permissions
**Problem:** Access denied to shared files
**Solution:** Ensure Q Developer process has read access to shared directory

### ⚠️ Registry Caching
**Problem:** Changes not reflected immediately
**Solution:** 
- Restart Q Developer
- Clear cache: `rm -rf ~/.aws/amazonq/cache/`

## Security Considerations

1. **File Permissions:** Restrict access to MCP server files
2. **Database Credentials:** Use service accounts with minimal privileges
3. **Network Security:** Ensure registry URL is only accessible internally
4. **Audit Logging:** Monitor MCP server usage and database access

## Troubleshooting

### Check Registry Configuration
```bash
# Verify Q Developer can access registry
q settings mcp.registryUrl
```

### Check MCP Server Status
```bash
# List available tools
q /tools

# Check server logs
tail -f ~/.aws/amazonq/logs/mcp-server.log
```

### Database Connection Test
```bash
# Test JDBC connection directly
java -cp "MCPServer-1.0.0-runner.jar:mssql-jdbc-12.4.2.jre11.jar" \
  -Djdbc.url="jdbc:sqlserver://SQLSERVER:1433;database=testdb;trustServerCertificate=true" \
  -Djdbc.user="bank_user" \
  -Djdbc.password="secure_password" \
  TestConnection
```

## References

- [AWS Q Developer MCP Documentation](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/qdev-mcp.html)
- [MCP Governance for Q Developer](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/mcp-governance.html)
- [MCP Registry Standard](https://github.com/modelcontextprotocol/registry)
- [Q Developer Profile Configuration](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/subscribe-understanding-profile.html)

## Next Steps

1. **Expand Registry:** Add more MCP servers for different databases/systems
2. **Automation:** Create CI/CD pipeline for registry updates
3. **Monitoring:** Implement logging and monitoring for MCP usage
4. **Documentation:** Create user guides for different database systems

---

**Note:** This setup ensures all MCP communication stays within the bank's internal network, meeting air-gapped security requirements while providing powerful database connectivity through Amazon Q Developer.
