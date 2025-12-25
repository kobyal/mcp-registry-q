# Amazon Q MCP Server Configuration Guide

## Issue: Environment Variables Are Grayed Out

The "REQUIRED" values in the Amazon Q UI are grayed out and cannot be edited because they come from the registry definition. You need to configure the MCP server manually.

---

## Solution: Manual Configuration

### Step 1: Close the "Edit MCP Server" Dialog

Click **Cancel** in the current dialog.

### Step 2: Find Your Amazon Q Configuration File

The configuration file location depends on your setup:

**Common locations:**
- `~/.aws/amazonq/mcp_servers.json`
- `~/.amazonq/mcp_servers.json`
- Or check Amazon Q Developer settings for the config file path

### Step 3: Edit the Configuration File

Open the file and add your MCP server configuration:

```json
{
  "mcpServers": {
    "global-jdbc-sql": {
      "command": "npx",
      "args": [
        "-y",
        "https://github.com/kobyal/mcp-registry-q/releases/download/v1.0.0/global-jdbc-sql-mcp-1.0.0.tgz"
      ],
      "env": {
        "jdbc.url": "jdbc:sqlserver://YOUR-SERVER:1433;database=YOUR-DB;trustServerCertificate=true;encrypt=false",
        "jdbc.user": "YOUR-USERNAME",
        "jdbc.password": "YOUR-PASSWORD"
      }
    }
  }
}
```

### Step 4: Replace with Your SQL Server Details

Edit these values:
- **YOUR-SERVER**: Your SQL Server hostname or IP (e.g., `sql-server.company.com` or `localhost`)
- **YOUR-DB**: Your database name (e.g., `testdb`, `master`, etc.)
- **YOUR-USERNAME**: Your SQL Server username (e.g., `sa`, `dbuser`)
- **YOUR-PASSWORD**: Your SQL Server password

**Example:**
```json
{
  "mcpServers": {
    "global-jdbc-sql": {
      "command": "npx",
      "args": [
        "-y",
        "https://github.com/kobyal/mcp-registry-q/releases/download/v1.0.0/global-jdbc-sql-mcp-1.0.0.tgz"
      ],
      "env": {
        "jdbc.url": "jdbc:sqlserver://localhost:1433;database=testdb;trustServerCertificate=true;encrypt=false",
        "jdbc.user": "sa",
        "jdbc.password": "MyPassword123"
      }
    }
  }
}
```

### Step 5: Save and Restart Amazon Q

1. Save the configuration file
2. Restart Amazon Q Developer
3. The MCP server should now connect successfully

---

## Alternative: Try Without Manual Config (If Amazon Q Prompts)

Some versions of Amazon Q may prompt you to enter environment variables after installing from registry. If you see a prompt, enter:

1. **jdbc.url**: `jdbc:sqlserver://YOUR-SERVER:1433;database=YOUR-DB;trustServerCertificate=true;encrypt=false`
2. **jdbc.user**: Your username
3. **jdbc.password**: Your password

---

## Testing the Connection

Once configured, test in Amazon Q chat:

```
Show me all schemas in the database
```

or

```
List all tables in the database
```

The MCP server should connect and return results.

---

## Troubleshooting

### Error: "Java not found"
Install Java 21 or higher:
```bash
# Check Java version
java -version

# Install Java (if needed)
# macOS:
brew install openjdk@21

# Ubuntu:
sudo apt install openjdk-21-jdk
```

### Error: "Connection refused"
- Check SQL Server is running
- Verify hostname/port are correct
- Check firewall allows connection on port 1433
- Try `trustServerCertificate=true;encrypt=false` in connection string

### Error: "Login failed"
- Verify username and password
- Check user has permission to access the database
- Try connecting with SQL Server Management Studio first

### Server Not Appearing
- Restart Amazon Q
- Check configuration file syntax is valid JSON
- Look for errors in Amazon Q logs

---

## Quick Copy-Paste Template

```json
{
  "mcpServers": {
    "global-jdbc-sql": {
      "command": "npx",
      "args": [
        "-y",
        "https://github.com/kobyal/mcp-registry-q/releases/download/v1.0.0/global-jdbc-sql-mcp-1.0.0.tgz"
      ],
      "env": {
        "jdbc.url": "jdbc:sqlserver://localhost:1433;database=master;trustServerCertificate=true;encrypt=false",
        "jdbc.user": "sa",
        "jdbc.password": "YourPassword"
      }
    }
  }
}
```

**Remember to change:**
- `localhost` → your SQL Server host
- `master` → your database name
- `sa` → your username
- `YourPassword` → your password

---

## Where to Find Amazon Q Config File

### Option 1: Check Amazon Q Settings
1. Open Amazon Q Developer Settings
2. Look for "MCP Configuration" or "Configuration File Path"
3. Note the path shown

### Option 2: Common Locations
```bash
# Check these locations
ls ~/.aws/amazonq/mcp_servers.json
ls ~/.amazonq/mcp_servers.json
ls ~/Library/Application\ Support/Amazon\ Q/mcp_servers.json
```

### Option 3: Create New File
If the file doesn't exist, create it:
```bash
mkdir -p ~/.aws/amazonq
nano ~/.aws/amazonq/mcp_servers.json
# Paste the configuration above
```

---

## Summary

**The grayed-out fields cannot be edited in the UI.** You must:
1. Cancel the dialog
2. Find Amazon Q's configuration file
3. Add the MCP server configuration with your SQL Server credentials
4. Restart Amazon Q

This is a limitation of how Amazon Q handles MCP registries - environment variables from the registry are read-only in the UI and must be configured manually in the config file.

---

**Need help?** Check `DEPLOYMENT-SUCCESS.md` for more details.
