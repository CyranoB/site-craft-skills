---
name: gcp-deploy
description: Deploy any static site directory to Google Cloud (Firebase Hosting) using your local CLI. Use this skill whenever the user wants to deploy, host, or publish a static website to GCP/Firebase. Triggers on "deploy this to GCP," "host on Google Cloud," "publish to Firebase," "deploy to GCP/Firebase," or any request to host a local static site on Google infrastructure. Works with single HTML files, multi-file projects, and asset-heavy directories. Requires the Firebase CLI (`firebase-tools`) to be installed and authenticated locally.
---

# GCP/Firebase Deploy

Deploy any static site directory to Google Cloud via Firebase Hosting. Firebase Hosting provides professional-grade static asset hosting with a global CDN and free SSL.

## When to use

After generating a static site with any other skill (landing-page-builder, scroll-sequence, or manually), run this to host it on Google Cloud. Also useful when the user has an existing static site directory they want to host on Firebase.

## Workflow

### 1. Identify the directory

The user provides a path to a directory containing static files. If they don't specify one, look for the most recently generated project.

The directory must contain an `index.html` at the root. If there's a single `.html` file with a different name, the deploy script will rename it automatically.

### 2. Check Prerequisites

The skill requires the Firebase CLI to be installed and authenticated. Before deploying, check if it's available:

```bash
firebase --version
```

If the command is not found, tell the user:
"Firebase CLI is not installed. To install it, run: `npm install -g firebase-tools`. Then log in with `firebase login`."

### 3. Deploy

Run the deploy script:

```bash
bash <skill-path>/scripts/deploy.sh <directory> [project-id]
```

The script:
- Ensures `index.html` exists
- Checks for `firebase.json` and `.firebaserc`; if missing, it scaffolds them for the target directory
- Runs `firebase deploy --only hosting`
- Returns JSON with `hostingUrl` and `projectId`

### 4. Present results

Tell the user:

- **Hosting URL**: The live site URL (e.g., `https://your-project.web.app`)
- **Project ID**: The GCP/Firebase project used for deployment

If the deploy fails, check:
- Is `firebase-tools` installed?
- Is the user logged in (`firebase login`)?
- Is the `project-id` valid and does the user have permissions?
- Is `index.html` present?
