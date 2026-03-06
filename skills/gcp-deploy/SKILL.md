---
name: gcp-deploy
description: Deploy any static site directory to Google Cloud (Firebase Hosting) using your local CLI. Use this skill whenever the user wants to deploy, host, or publish a static website to GCP/Firebase. Triggers on "deploy this to GCP," "host on Google Cloud," "publish to Firebase," "deploy to GCP/Firebase," or any request to host a local static site on Google infrastructure. Works with single HTML files, multi-file projects, and asset-heavy directories. Requires the Firebase CLI (`firebase-tools`) to be installed and authenticated locally.
---

# GCP/Firebase Deploy

Deploy any static site directory to Google Cloud via Firebase Hosting. Firebase Hosting provides professional-grade static asset hosting with a global CDN and free SSL.

## When to use

- User explicitly requests GCP or Firebase hosting
- User already has a Firebase project and is logged in via `firebase login`
- User wants free hosting with a global CDN and SSL out of the box
- No practical file size limit (2GB per file) — suitable for large scroll-sequence sites

For quick deploys without any account, use `vercel-deploy` instead. For AWS-native workflows with CloudFormation teardown, use `aws-deploy`.

## Workflow

### 1. Identify the directory

The user provides a path to a directory containing static files. If they don't specify one, look for the most recently generated project.

The directory must contain an `index.html` at the root. If there's a single `.html` file with a different name, the deploy script will rename it automatically.

### 2. Check Prerequisites

The skill requires the Firebase CLI to be installed and authenticated. The deploy script auto-installs `firebase-tools` via npm if missing, but the user must be logged in.

If the script reports an authentication error, tell the user to run `firebase login`.

### 3. Deploy

Run the deploy script:

```bash
bash <skill-path>/scripts/deploy.sh <directory> [project-id]
```

The `project-id` is required on the first deploy if no `.firebaserc` exists in the directory. The user can find available projects with `firebase projects:list`.

The script:
- Ensures `index.html` exists
- Scaffolds `firebase.json` and `.firebaserc` if missing (cleans them up on failure)
- Runs `firebase deploy --only hosting`
- Returns JSON with `hostingUrl` and `projectId`

### 4. Present results

Tell the user:

- **Hosting URL**: The live site URL (e.g., `https://your-project.web.app`)
- **Project ID**: The GCP/Firebase project used for deployment

If the deploy fails, check:
- Is the user logged in (`firebase login`)?
- Is the `project-id` valid and does the user have permissions?
- Is `index.html` present?
- Does npm exist (needed for auto-install of `firebase-tools`)?

### 5. Cleanup

To remove a deployment and stop hosting:

```bash
firebase hosting:disable --project <project-id>
```

To delete the Firebase project entirely, use the [Firebase Console](https://console.firebase.google.com/).
