# Amazon Q MCP Config Updated ✅

**Date:** December 25, 2024
**Action:** Added `global-jdbc-sql` MCP server to your Amazon Q configuration

---

## What I Did

### 1. Backed Up Your Config
```
Original: ~/.aws/amazonq/mcp.json
Backup:   ~/.aws/amazonq/mcp.json.backup.20251225-132646
```

Your original config is safe! You can restore it anytime:
```bash
cp ~/.aws/amazonq/mcp.json.backup.20251225-132646 ~/.aws/amazonq/mcp.json
```

### 2. Added JDBC MCP Server

Added this configuration to `~/.aws/amazonq/mcp.json`:

```json
"global-jdbc-sql": {
  "command": "npx",
  "args": [
    "-y",
    "https://github.com/kobyal/mcp-registry-q/releases/download/v1.0.0/global-jdbc-sql-mcp-1.0.0.tgz"
  ],
  "env": {
    "jdbc.url": "jdbc:sqlserver://localhost:1433;database=testdb;trustServerCertificate=true;encrypt=false",
    "jdbc.user": "sa",
    "jdbc.password": "YourPassword123"
  },
  "timeout": 60000,
  "disabled": false
}
```

**Mock Data Used:**
- Host: `localhost:1433`
- Database: `testdb`
- User: `sa`
- Password: `YourPassword123`

---

## What You Need to Do Now

### Step 1: Restart Amazon Q Developer

The config changes require a restart to take effect.

**How to restart:**
- Close Amazon Q completely
- Reopen it

### Step 2: Check if User Can Edit the Values

1. Open Amazon Q settings
2. Navigate to MCP servers
3. Find `global-jdbc-sql`
4. Try to **edit the environment variables**

**Test:** Can the user now change these values?
- `jdbc.url`
- `jdbc.user`
- `jdbc.password`

### Step 3: Verify It Appears in the List

The `global-jdbc-sql` server should now appear in your MCP servers list alongside:
- awslabs.bedrock-kb-retrieval-mcp-server
- awslabs.cdk-mcp-server
- AWSDocMCPServer
- etc.

---

## To Actually Test Connection (Later)

When you have real SQL Server credentials, edit the config:

```bash
nano ~/.aws/amazonq/mcp.json
```

Update these values:
- Change `localhost` to your SQL Server hostname/IP
- Change `testdb` to your actual database name
- Change `sa` to your SQL Server username
- Change `YourPassword123` to your actual password

Then restart Amazon Q and test with:
```
Show me all schemas in the database
```

---

## To Restore Original Config

If anything goes wrong:

```bash
cp ~/.aws/amazonq/mcp.json.backup.20251225-132646 ~/.aws/amazonq/mcp.json
```

Then restart Amazon Q.

---

## Expected Behavior

After restart, you should see one of these:

**✅ Success:**
- Server appears in MCP list
- User can edit environment variables in UI
- Connection will fail (expected - mock credentials)

**❌ If it doesn't work:**
- Check Amazon Q logs for errors
- Verify JSON syntax is valid: `cat ~/.aws/amazonq/mcp.json | jq .`
- Restore backup and try manual install

---

## Files Reference

- **Config file:** `~/.aws/amazonq/mcp.json`
- **Backup:** `~/.aws/amazonq/mcp.json.backup.20251225-132646`
- **Tarball:** `https://github.com/kobyal/mcp-registry-q/releases/download/v1.0.0/global-jdbc-sql-mcp-1.0.0.tgz`

---

**Status:** Configuration updated, ready for testing!

**Next:** Restart Amazon Q and check if the server appears with editable fields.
