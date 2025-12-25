# GitHub Pages Setup - Quick Guide

## Status: Repository initialized and ready to push

✓ Git repository initialized
✓ Files committed to `main` branch
✓ .gitignore created (excludes large JAR files)

---

## Step 1: Create GitHub Repository

1. Go to [GitHub](https://github.com/new)
2. **Repository name:** `mcp-registry` (or any name you prefer)
3. **Visibility:** Public (required for GitHub Pages free tier)
4. **DO NOT** initialize with README, .gitignore, or license (we already have them)
5. Click **Create repository**

---

## Step 2: Push to GitHub

Copy the commands from GitHub's "push an existing repository" section, or use:

```bash
cd /Users/kobyalmog/vscode/projects/mcp-registry

# Replace YOUR_USERNAME with your GitHub username
git remote add origin https://github.com/YOUR_USERNAME/mcp-registry.git

# Push to GitHub
git push -u origin main
```

**Alternative with SSH (if you have SSH keys set up):**
```bash
git remote add origin git@github.com:YOUR_USERNAME/mcp-registry.git
git push -u origin main
```

---

## Step 3: Enable GitHub Pages

1. Go to your repository on GitHub
2. Click **Settings** (top menu)
3. Click **Pages** (left sidebar)
4. Under "Source":
   - Select branch: **main**
   - Select folder: **/ (root)**
5. Click **Save**

Wait 1-2 minutes for deployment. GitHub will show:
```
Your site is live at https://YOUR_USERNAME.github.io/mcp-registry/
```

---

## Step 4: Upload JAR Files to GitHub Releases

Since JAR files are too large for regular commits (71 MB total), use GitHub Releases:

1. Go to your repository
2. Click **Releases** (right sidebar)
3. Click **Create a new release**
4. **Tag:** `v1.0.0`
5. **Release title:** `MCP Server v1.0.0`
6. **Description:**
   ```
   JDBC SQL Server MCP Server for Amazon Q Developer

   Files included:
   - MCPServer-1.0.0-runner.jar (18 MB) - Main MCP server
   - mssql-jdbc-12.4.2.jre11.jar (1.4 MB) - SQL Server JDBC driver
   ```
7. **Attach files:**
   - Drag and drop `MCPServer-1.0.0-runner.jar`
   - Drag and drop `mssql-jdbc-12.4.2.jre11.jar`
8. Click **Publish release**

After publishing, GitHub will provide URLs like:
```
https://github.com/YOUR_USERNAME/mcp-registry/releases/download/v1.0.0/MCPServer-1.0.0-runner.jar
https://github.com/YOUR_USERNAME/mcp-registry/releases/download/v1.0.0/mssql-jdbc-12.4.2.jre11.jar
```

---

## Step 5: Update registry.json with GitHub URLs

Once you have the release URLs, update `registry.json`:

```bash
# I'll help you update this in the next step
# Just provide me with your GitHub username
```

---

## Step 6: Test Your Registry

```bash
# Replace YOUR_USERNAME with your GitHub username
curl https://YOUR_USERNAME.github.io/mcp-registry/registry.json

# Should return valid JSON
```

---

## Step 7: Configure Amazon Q

1. Open Amazon Q Developer settings
2. Navigate to MCP section
3. Add registry URL:
   ```
   https://YOUR_USERNAME.github.io/mcp-registry/registry.json
   ```
4. Save and restart Q Developer if needed

---

## Troubleshooting

### Issue: 404 Page Not Found

**Wait 2-3 minutes** - GitHub Pages takes time to build and deploy.

Check deployment status:
- Go to repository → Actions tab
- Look for "pages build and deployment" workflow

### Issue: JAR files too large to upload

If JAR files fail to upload to release:
- Make sure you're using **Releases** (not regular commits)
- GitHub Releases support files up to 2 GB each
- Both JAR files (18 MB + 1.4 MB) are well under the limit

### Issue: Registry returns HTML instead of JSON

Make sure the URL is:
```
https://YOUR_USERNAME.github.io/mcp-registry/registry.json
```

Not:
```
https://YOUR_USERNAME.github.io/mcp-registry/
```

---

## Quick Commands Reference

```bash
# Check current remote
git remote -v

# Push changes
git push origin main

# Update after editing files
git add registry.json
git commit -m "Update registry URLs"
git push origin main
```

---

## What's Next?

After completing these steps, provide me with your **GitHub username** and I'll:
1. Update the registry.json with correct GitHub Release URLs
2. Commit and push the changes
3. Verify the registry is accessible
4. Help you test with Amazon Q

---

**Estimated total time:** 10-15 minutes
