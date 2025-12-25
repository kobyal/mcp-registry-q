# Global JDBC SQL MCP Server

NPM wrapper for the Global JDBC SQL MCP Server that provides SQL Server database connectivity via JDBC.

## Installation

```bash
npm install -g @koby/global-jdbc-sql
```

## Usage

The package automatically downloads the required JAR files during installation and provides a `global-jdbc-sql` command.

## Environment Variables

- `jdbc.url` - JDBC connection string (required)
- `jdbc.user` - Database username (required)  
- `jdbc.password` - Database password (required)

## Example

```bash
export jdbc.url="jdbc:sqlserver://localhost:1433;database=testdb;trustServerCertificate=true;encrypt=false"
export jdbc.user="sa"
export jdbc.password="password"
global-jdbc-sql
```
