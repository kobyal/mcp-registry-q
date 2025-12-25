#!/usr/bin/env node

const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

// Path to the JAR files (downloaded during postinstall)
const jarDir = path.join(__dirname, '..', 'jars');
const mcpJar = path.join(jarDir, 'MCPServer-1.0.0-runner.jar');
const jdbcJar = path.join(jarDir, 'mssql-jdbc-12.4.2.jre11.jar');

// Check if JAR files exist
if (!fs.existsSync(mcpJar) || !fs.existsSync(jdbcJar)) {
  console.error('JAR files not found. Please run: npm install');
  process.exit(1);
}

// Java command with classpath
const javaArgs = [
  '-Xms512m',
  '-Xmx2g',
  '-XX:+UseG1GC',
  '-XX:MaxGCPauseMillis=200',
  '-Dfile.encoding=UTF-8',
  '-Dsun.stdout.encoding=UTF-8',
  '-Dsun.stderr.encoding=UTF-8',
  '-cp',
  `${mcpJar}:${jdbcJar}`,
  'io.quarkus.runner.GeneratedMain'
];

// Spawn Java process
const child = spawn('java', javaArgs, {
  stdio: 'inherit',
  env: process.env
});

// Handle process exit
child.on('exit', (code) => {
  process.exit(code || 0);
});

// Handle errors
child.on('error', (err) => {
  console.error('Failed to start MCP server:', err);
  process.exit(1);
});
