#!/bin/bash

# GCP/Firebase Deployment Script
# Usage: ./deploy.sh [project-path] [project-id]
# Returns: JSON with hostingUrl, projectId

set -e

# Parse arguments
INPUT_PATH="${1:-.}"
PROJECT_ID="$2"

# ── Check for Firebase CLI ──────────────────────────────────────────────────

if ! command -v firebase &>/dev/null; then
    echo "Firebase CLI ('firebase-tools') not found. Installing..." >&2
    if command -v npm &>/dev/null; then
        npm install -g firebase-tools 2>&1 >&2
    else
        echo "Error: Node.js and npm are required to install Firebase CLI." >&2
        echo "Install Node.js from https://nodejs.org/ or use your package manager." >&2
        exit 1
    fi

    if ! command -v firebase &>/dev/null; then
        echo "Error: Firebase CLI installation failed" >&2
        exit 1
    fi
    echo "Firebase CLI installed." >&2
fi

# ── Check for Authentication ────────────────────────────────────────────────

if ! firebase login:list 2>/dev/null | grep -q "Logged in"; then
    echo "" >&2
    echo "Error: Not authenticated with Firebase." >&2
    echo "" >&2
    echo "Please log in by running:" >&2
    echo "  firebase login" >&2
    echo "" >&2
    exit 1
fi

# Determine project path
if [ -d "$INPUT_PATH" ]; then
    PROJECT_PATH=$(cd "$INPUT_PATH" && pwd)
else
    echo "Error: Input path must be a directory" >&2
    exit 1
fi

# Track scaffolded files for cleanup on failure
SCAFFOLDED_FILES=()

cleanup_on_failure() {
    for f in "${SCAFFOLDED_FILES[@]}"; do
        [ -f "$f" ] && rm -f "$f"
    done
}
trap 'cleanup_on_failure' ERR

# Static HTML project: ensure index.html exists
HTML_FILES=$(find "$PROJECT_PATH" -maxdepth 1 -name "*.html" -type f)
HTML_COUNT=$(echo "$HTML_FILES" | grep -c . || echo 0)

if [ "$HTML_COUNT" -eq 1 ]; then
    HTML_FILE=$(echo "$HTML_FILES" | head -1)
    BASENAME=$(basename "$HTML_FILE")
    if [ "$BASENAME" != "index.html" ]; then
        echo "Renaming $BASENAME to index.html..." >&2
        mv "$HTML_FILE" "$PROJECT_PATH/index.html"
    fi
elif [ "$HTML_COUNT" -eq 0 ]; then
    echo "Error: No .html files found in $PROJECT_PATH" >&2
    exit 1
fi

cd "$PROJECT_PATH"

# Scaffold firebase.json if missing
if [ ! -f "firebase.json" ]; then
    echo "Creating firebase.json..." >&2
    cat > "firebase.json" <<EOF
{
  "hosting": {
    "public": ".",
    "ignore": [
      "firebase.json",
      ".firebaserc",
      "**/.*",
      "**/node_modules/**"
    ]
  }
}
EOF
    SCAFFOLDED_FILES+=("$PROJECT_PATH/firebase.json")
fi

# Scaffold .firebaserc if missing
if [ ! -f ".firebaserc" ]; then
    if [ -z "$PROJECT_ID" ]; then
        echo "" >&2
        echo "Error: No Firebase project specified and no .firebaserc found." >&2
        echo "" >&2
        echo "Either pass a project ID:" >&2
        echo "  deploy.sh <directory> <project-id>" >&2
        echo "" >&2
        echo "Or pick from your available projects:" >&2
        firebase projects:list --non-interactive 2>/dev/null >&2 || true
        echo "" >&2
        cleanup_on_failure
        exit 1
    fi
    echo "Creating .firebaserc for project $PROJECT_ID..." >&2
    cat > ".firebaserc" <<EOF
{
  "projects": {
    "default": "$PROJECT_ID"
  }
}
EOF
    SCAFFOLDED_FILES+=("$PROJECT_PATH/.firebaserc")
fi

# Deploy to Firebase
echo "Deploying to Firebase..." >&2
if [ -n "$PROJECT_ID" ]; then
    # Use specified project
    DEPLOY_CMD="firebase deploy --only hosting --project $PROJECT_ID --non-interactive"
else
    # Use project from .firebaserc
    DEPLOY_CMD="firebase deploy --only hosting --non-interactive"
fi

# Execute deployment and capture output
DEPLOY_OUTPUT=$($DEPLOY_CMD 2>&1) || {
    echo "Error: Firebase deployment failed" >&2
    echo "$DEPLOY_OUTPUT" >&2
    exit 1
}

# Extract Hosting URL and Project ID from output
# Typical success line: Project Console: https://console.firebase.google.com/project/my-project/overview
# Hosting URL: https://my-project.web.app
HOSTING_URL=$(echo "$DEPLOY_OUTPUT" | grep -o 'Hosting URL: [^ ]*' | cut -d' ' -f3)
EXTRACTED_PROJECT_ID=$(echo "$DEPLOY_OUTPUT" | grep -o 'Project Console: [^ ]*' | cut -d'/' -f6)

if [ -z "$HOSTING_URL" ]; then
    # Fallback if the regex fails
    HOSTING_URL=$(echo "$DEPLOY_OUTPUT" | grep "Hosting URL" | awk '{print $NF}')
fi

if [ -z "$EXTRACTED_PROJECT_ID" ]; then
    EXTRACTED_PROJECT_ID="$PROJECT_ID"
fi

echo "" >&2
echo "Deployment successful!" >&2
echo "" >&2
echo "Hosting URL: $HOSTING_URL" >&2
echo "Project ID:  $EXTRACTED_PROJECT_ID" >&2
echo "" >&2

# Output JSON for programmatic use
cat <<EOF
{
  "hostingUrl": "$HOSTING_URL",
  "projectId": "$EXTRACTED_PROJECT_ID"
}
EOF
