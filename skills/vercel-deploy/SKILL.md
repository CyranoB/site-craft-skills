---
name: vercel-deploy
description: Deploy any static site directory to Vercel instantly — no authentication required. Use this skill whenever the user wants to deploy, host, publish, or put live any static website, HTML project, or directory containing an index.html. Triggers on "deploy this to Vercel," "put this live," "host this site," "publish this page," "deploy this directory," "I want to see this online," or any request to make a local static site accessible via a public URL. Works with single HTML files, multi-file projects (HTML + CSS + JS), and asset-heavy directories (images, fonts, frames). Returns a live preview URL and a claim URL to transfer ownership.
---

# Vercel Deploy

Deploy any static site directory to Vercel using claimable deployments. No authentication, no config, no build step — just point at a directory and get a live URL.

## When to use

After generating a static site with any other skill (landing-page-builder, scroll-sequence, or manually), run this to put it live. Also useful when the user has an existing static site directory they want to host.

## Workflow

### 1. Identify the directory

The user provides a path to a directory containing static files. If they don't specify one, look for the most recently generated project (e.g., `/tmp/landing-page/`, or whatever the upstream skill produced).

The directory must contain an `index.html` at the root. If there's a single `.html` file with a different name, the deploy script will rename it automatically.

### 2. Check size

The Vercel deploy endpoint has upload limits. Before deploying, check the total size:

```bash
du -sh <directory>
```

- **Under 50MB**: Deploy directly
- **50-100MB**: Warn the user it may be slow, but proceed
- **Over 100MB**: Suggest reducing asset sizes (e.g., lower frame count, compress images) before deploying

For scroll-sequence sites with many frames, the typical size is 10-25MB — well within limits.

### 3. Deploy

Run the deploy script:

```bash
bash <skill-path>/scripts/deploy.sh <directory>
```

The script:
- Packages the directory into a `.tgz` (excluding `node_modules` and `.git`)
- POSTs it to Vercel's claimable deploy endpoint
- Returns JSON with `previewUrl`, `claimUrl`, `deploymentId`, `projectId`

### 4. Present results

Tell the user:

- **Preview URL**: The live site — share this anywhere
- **Claim URL**: Transfer ownership to their Vercel account (optional, expires after 7 days)

If the deploy fails, check:
- Is `curl` available?
- Is the directory path correct?
- Is `index.html` present?
- Is the payload under the size limit?
