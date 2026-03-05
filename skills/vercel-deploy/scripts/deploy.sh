#!/bin/bash

# Vercel Deployment Script (via claimable deploy endpoint)
# Usage: ./deploy.sh [project-path]
# Returns: JSON with previewUrl, claimUrl, deploymentId, projectId

set -e

DEPLOY_ENDPOINT="https://claude-skills-deploy.vercel.com/api/deploy"

# Parse arguments
INPUT_PATH="${1:-.}"

# Create temp directory for packaging
TEMP_DIR=$(mktemp -d)
TARBALL="$TEMP_DIR/project.tgz"
CLEANUP_TEMP=true

cleanup() {
    if [ "$CLEANUP_TEMP" = true ]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

echo "Preparing deployment..." >&2

if [ -f "$INPUT_PATH" ] && [[ "$INPUT_PATH" == *.tgz ]]; then
    echo "Using provided tarball..." >&2
    TARBALL="$INPUT_PATH"
    CLEANUP_TEMP=false
elif [ -d "$INPUT_PATH" ]; then
    PROJECT_PATH=$(cd "$INPUT_PATH" && pwd)

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
    fi

    echo "Creating deployment package..." >&2
    tar -czf "$TARBALL" -C "$PROJECT_PATH" --exclude='node_modules' --exclude='.git' .
else
    echo "Error: Input must be a directory or a .tgz file" >&2
    exit 1
fi

echo "Deploying to Vercel..." >&2
RESPONSE=$(curl -s -X POST "$DEPLOY_ENDPOINT" -F "file=@$TARBALL" -F "framework=null")

# Check for error in response
if echo "$RESPONSE" | grep -q '"error"'; then
    ERROR_MSG=$(echo "$RESPONSE" | grep -o '"error":"[^"]*"' | cut -d'"' -f4)
    echo "Error: $ERROR_MSG" >&2
    exit 1
fi

PREVIEW_URL=$(echo "$RESPONSE" | grep -o '"previewUrl":"[^"]*"' | cut -d'"' -f4)
CLAIM_URL=$(echo "$RESPONSE" | grep -o '"claimUrl":"[^"]*"' | cut -d'"' -f4)

if [ -z "$PREVIEW_URL" ]; then
    echo "Error: Could not extract preview URL from response" >&2
    echo "$RESPONSE" >&2
    exit 1
fi

echo "" >&2
echo "Deployment successful!" >&2
echo "" >&2
echo "Preview URL: $PREVIEW_URL" >&2
echo "Claim URL:   $CLAIM_URL" >&2
echo "" >&2

# Output JSON for programmatic use
echo "$RESPONSE"
