const fs = require('fs');
const path = require('path');
const https = require('https');

const jarDir = path.join(__dirname, '..', 'jars');
const baseUrl = 'https://github.com/kobyal/mcp-registry-q/releases/download/v1.0.0';

// Create jars directory
if (!fs.existsSync(jarDir)) {
  fs.mkdirSync(jarDir, { recursive: true });
}

// Download function
function downloadFile(url, dest) {
  return new Promise((resolve, reject) => {
    const file = fs.createWriteStream(dest);
    https.get(url, (response) => {
      if (response.statusCode !== 200) {
        reject(new Error(`HTTP ${response.statusCode}: ${response.statusMessage}`));
        return;
      }
      response.pipe(file);
      file.on('finish', () => {
        file.close();
        resolve();
      });
    }).on('error', (err) => {
      fs.unlink(dest, () => {}); // Delete partial file
      reject(err);
    });
  });
}

// Download JAR files
async function downloadJars() {
  console.log('Downloading MCP SQL Server JAR files...');
  
  try {
    await downloadFile(
      `${baseUrl}/MCPServer-1.0.0-runner.jar`,
      path.join(jarDir, 'MCPServer-1.0.0-runner.jar')
    );
    console.log('✓ Downloaded MCP Server JAR');
    
    await downloadFile(
      `${baseUrl}/mssql-jdbc-12.4.2.jre11.jar`,
      path.join(jarDir, 'mssql-jdbc-12.4.2.jre11.jar')
    );
    console.log('✓ Downloaded JDBC Driver JAR');
    
    console.log('Installation complete!');
  } catch (error) {
    console.error('Failed to download JAR files:', error);
    process.exit(1);
  }
}

if (require.main === module) {
  downloadJars();
}
