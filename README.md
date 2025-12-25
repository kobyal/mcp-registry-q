# MCP SQL Server Registry

A Model Context Protocol (MCP) server for connecting Amazon Q Developer to SQL Server databases via JDBC.

## 🚀 Quick Start

### Manual Installation (Required)

Since this MCP server uses JAR files, manual configuration is required:

1. **Download JAR files:**
   - [MCPServer-1.0.0-runner.jar](https://mcp-sql-registry-koby.s3.amazonaws.com/MCPServer-1.0.0-runner.jar) (17.4 MB)
   - [mssql-jdbc-12.4.2.jre11.jar](https://mcp-sql-registry-koby.s3.amazonaws.com/mssql-jdbc-12.4.2.jre11.jar) (1.4 MB)

2. **Place files in a directory** (e.g., `~/.mcp/global-jdbc-sql/`)

3. **Add MCP server manually in Amazon Q Developer:**

```bash
# Download and run the installation script
curl -sSL https://mcp-sql-registry-koby.s3.amazonaws.com/install.sh | bash
```

## 📋 Prerequisites

- **Java 21+** installed and available in PATH
- **Amazon Q Developer** with MCP support enabled
- **SQL Server** database access credentials

## ⚙️ Configuration

### Amazon Q Developer Settings

1. Open Amazon Q Developer settings
2. Navigate to **MCP** section
3. Add registry URL: `https://mcp-sql-registry-koby.s3.amazonaws.com/registry.json`
4. Or manually configure the server:

```json
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
        "MCPServer-1.0.0-runner.jar:mssql-jdbc-12.4.2.jre11.jar",
        "io.quarkus.runner.GeneratedMain"
      ],
      "env": {
        "jdbc.url": "jdbc:sqlserver://your-host:1433;database=your-db;trustServerCertificate=true;encrypt=false",
        "jdbc.user": "your-username",
        "jdbc.password": "your-password"
      },
      "timeout": 60000,
      "disabled": false
    }
  }
}
```

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `jdbc.url` | JDBC connection string | `jdbc:sqlserver://localhost:1433;database=testdb;trustServerCertificate=true;encrypt=false` |
| `jdbc.user` | Database username | `sa` |
| `jdbc.password` | Database password | `YourPassword123` |

## 🛠️ Available Tools

The MCP server provides these capabilities:

- **jdbc_execute_query** - Execute SQL queries and return JSON results
- **jdbc_execute_query_md** - Execute SQL queries and return Markdown formatted results
- **jdbc_query_database** - General database querying
- **jdbc_get_schemas** - List all database schemas
- **jdbc_get_tables** - List tables in a schema
- **jdbc_describe_table** - Get table structure and column information
- **jdbc_filter_table_names** - Search for tables by name pattern

## 💡 Usage Examples

### Basic Queries
```
Show me all schemas in the database
```

```
List all tables in the 'dbo' schema
```

```
Describe the structure of the 'users' table
```

### Data Analysis
```
Show me the top 10 customers by order count
```

```
What's the average order value by month for the last year?
```

## 🔧 Troubleshooting

### Common Issues

**Java Not Found**
```bash
# Check Java installation
java -version
# Should show Java 21 or higher
```

**Connection Issues**
- Verify database host and port are accessible
- Check username/password credentials
- Ensure SQL Server allows TCP/IP connections
- For SSL issues, use `trustServerCertificate=true;encrypt=false`

**Classpath Issues**
- Ensure both JAR files are in the same directory
- Use correct path separator (`:` on Unix, `;` on Windows)

### Debug Mode

Add these JVM arguments for debugging:
```json
"-Dquarkus.log.level=DEBUG",
"-Djava.util.logging.manager=org.jboss.logmanager.LogManager"
```

## 📁 File Structure

```
~/.mcp/global-jdbc-sql/
├── MCPServer-1.0.0-runner.jar     # Main MCP server
├── mssql-jdbc-12.4.2.jre11.jar    # SQL Server JDBC driver
└── sample-config.json              # Sample configuration
```

## 🔐 Security Considerations

- Store database credentials securely
- Use service accounts with minimal required permissions
- Consider using connection pooling for production environments
- Enable SSL/TLS for database connections when possible

## 📚 Resources

- [MCP Specification](https://modelcontextprotocol.io/)
- [Amazon Q Developer Documentation](https://docs.aws.amazon.com/amazonq/)
- [SQL Server JDBC Driver Documentation](https://docs.microsoft.com/en-us/sql/connect/jdbc/)

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section above
2. Verify your Java and database connectivity
3. Review the MCP server logs in Amazon Q Developer

---

**Registry URL:** `https://mcp-sql-registry-koby.s3.amazonaws.com/registry.json`

**Last Updated:** December 2025
