#!/bin/bash

# AWS S3 + CloudFront Deployment Script
# Usage: ./deploy.sh <directory> [--region <region>]
# Returns: JSON with previewUrl, distributionId, bucketName, stackName, region
# Status messages go to stderr; JSON output goes to stdout

set -e

# ── Parse arguments ─────────────────────────────────────────────────────────

INPUT_PATH=""
REGION="${AWS_REGION:-us-east-1}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --region)
            REGION="$2"
            shift 2
            ;;
        *)
            INPUT_PATH="$1"
            shift
            ;;
    esac
done

if [ -z "$INPUT_PATH" ]; then
    echo "Usage: deploy.sh <directory> [--region <region>]" >&2
    exit 1
fi

if [ ! -d "$INPUT_PATH" ]; then
    echo "Error: '$INPUT_PATH' is not a directory" >&2
    exit 1
fi

PROJECT_PATH=$(cd "$INPUT_PATH" && pwd)

# ── Check for AWS CLI ───────────────────────────────────────────────────────

if ! command -v aws &>/dev/null; then
    echo "AWS CLI not found. Installing..." >&2
    if [[ "$OSTYPE" == darwin* ]]; then
        if command -v brew &>/dev/null; then
            brew install awscli >&2
        else
            echo "Error: Install AWS CLI manually — https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html" >&2
            exit 1
        fi
    elif [[ "$OSTYPE" == linux* ]]; then
        TEMP_DIR=$(mktemp -d)
        curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$TEMP_DIR/awscliv2.zip" >&2
        unzip -q "$TEMP_DIR/awscliv2.zip" -d "$TEMP_DIR" >&2
        "$TEMP_DIR/aws/install" --install-dir "$TEMP_DIR/aws-cli" --bin-dir "$TEMP_DIR/bin" >&2
        export PATH="$TEMP_DIR/bin:$PATH"
        rm -rf "$TEMP_DIR/awscliv2.zip" "$TEMP_DIR/aws"
    else
        echo "Error: Unsupported OS. Install AWS CLI manually — https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html" >&2
        exit 1
    fi

    if ! command -v aws &>/dev/null; then
        echo "Error: AWS CLI installation failed" >&2
        exit 1
    fi
    echo "AWS CLI installed." >&2
fi

# ── Check for credentials ──────────────────────────────────────────────────

ACCOUNT_ID=$(aws sts get-caller-identity --region "$REGION" --query 'Account' --output text 2>/dev/null) || {
    echo "" >&2
    echo "Error: No valid AWS credentials found." >&2
    echo "" >&2
    echo "Set up credentials using one of these methods:" >&2
    echo "  1. Run:  aws configure" >&2
    echo "  2. Set environment variables:" >&2
    echo "     export AWS_ACCESS_KEY_ID=<your-key>" >&2
    echo "     export AWS_SECRET_ACCESS_KEY=<your-secret>" >&2
    echo "  3. Use AWS SSO:  aws sso login" >&2
    echo "" >&2
    exit 1
}
echo "Using AWS account $ACCOUNT_ID in $REGION" >&2

# ── Derive stack name from directory ────────────────────────────────────────

DIR_NAME=$(basename "$PROJECT_PATH")
SANITIZED=$(echo "$DIR_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')

if [ -z "$SANITIZED" ]; then
    echo "Error: Could not derive a valid stack name from directory '$DIR_NAME'" >&2
    exit 1
fi

STACK_NAME="site-craft-${SANITIZED}"

# CloudFormation stack names max 128 chars
STACK_NAME="${STACK_NAME:0:128}"

echo "Stack name: $STACK_NAME" >&2

# ── Auto-rename single HTML file to index.html ─────────────────────────────

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

# ── Resolve CloudFormation template path ────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_PATH="$SCRIPT_DIR/../cloudformation/static-site.yaml"

if [ ! -f "$TEMPLATE_PATH" ]; then
    echo "Error: CloudFormation template not found at $TEMPLATE_PATH" >&2
    exit 1
fi

# ── Create or update CloudFormation stack ───────────────────────────────────

STACK_STATUS=""
if aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" &>/dev/null; then
    STACK_STATUS=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$REGION" \
        --query 'Stacks[0].StackStatus' \
        --output text)
fi

create_stack() {
    echo "Creating CloudFormation stack (this takes 3-5 minutes for CloudFront)..." >&2
    aws cloudformation create-stack \
        --stack-name "$STACK_NAME" \
        --region "$REGION" \
        --template-body "file://$TEMPLATE_PATH" \
        --parameters "ParameterKey=SiteName,ParameterValue=$SANITIZED" \
        --on-failure DELETE \
        >/dev/null

    echo "Waiting for stack creation..." >&2
    aws cloudformation wait stack-create-complete \
        --stack-name "$STACK_NAME" \
        --region "$REGION" >&2

    STACK_STATUS=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$REGION" \
        --query 'Stacks[0].StackStatus' \
        --output text)

    if [ "$STACK_STATUS" != "CREATE_COMPLETE" ]; then
        echo "Error: Stack creation failed with status $STACK_STATUS" >&2
        exit 1
    fi
    echo "Stack created." >&2
}

if [ -z "$STACK_STATUS" ]; then
    create_stack
elif [ "$STACK_STATUS" = "ROLLBACK_COMPLETE" ] || [ "$STACK_STATUS" = "DELETE_COMPLETE" ]; then
    echo "Stack in $STACK_STATUS state. Deleting and recreating..." >&2
    aws cloudformation delete-stack --stack-name "$STACK_NAME" --region "$REGION" >/dev/null
    aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" --region "$REGION" >&2
    create_stack
elif [ "$STACK_STATUS" = "CREATE_COMPLETE" ] || [ "$STACK_STATUS" = "UPDATE_COMPLETE" ] || [ "$STACK_STATUS" = "UPDATE_ROLLBACK_COMPLETE" ]; then
    echo "Stack already exists ($STACK_STATUS). Uploading content..." >&2
elif [[ "$STACK_STATUS" == *"IN_PROGRESS"* ]]; then
    echo "Stack operation in progress ($STACK_STATUS). Waiting..." >&2
    if [[ "$STACK_STATUS" == "CREATE_IN_PROGRESS" ]]; then
        aws cloudformation wait stack-create-complete --stack-name "$STACK_NAME" --region "$REGION" >&2
    elif [[ "$STACK_STATUS" == "UPDATE_IN_PROGRESS" ]]; then
        aws cloudformation wait stack-update-complete --stack-name "$STACK_NAME" --region "$REGION" >&2
    elif [[ "$STACK_STATUS" == "DELETE_IN_PROGRESS" ]]; then
        aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" --region "$REGION" >&2
        create_stack
    elif [[ "$STACK_STATUS" == *"ROLLBACK_IN_PROGRESS"* ]]; then
        # Wait for rollback to finish by polling
        echo "Waiting for rollback to complete..." >&2
        while true; do
            sleep 10
            STACK_STATUS=$(aws cloudformation describe-stacks \
                --stack-name "$STACK_NAME" --region "$REGION" \
                --query 'Stacks[0].StackStatus' --output text 2>/dev/null) || break
            [[ "$STACK_STATUS" == *"IN_PROGRESS"* ]] || break
        done
        if [ "$STACK_STATUS" = "ROLLBACK_COMPLETE" ]; then
            echo "Rollback complete. Deleting and recreating..." >&2
            aws cloudformation delete-stack --stack-name "$STACK_NAME" --region "$REGION" >/dev/null
            aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" --region "$REGION" >&2
            create_stack
        elif [ "$STACK_STATUS" = "UPDATE_ROLLBACK_COMPLETE" ]; then
            echo "Rollback complete. Stack is usable." >&2
        else
            echo "Error: Stack in unexpected state after rollback: $STACK_STATUS" >&2
            exit 1
        fi
    else
        echo "Error: Stack in unexpected in-progress state: $STACK_STATUS" >&2
        exit 1
    fi
    echo "Stack ready." >&2
else
    echo "Error: Stack in unexpected state: $STACK_STATUS" >&2
    exit 1
fi

# ── Get stack outputs ───────────────────────────────────────────────────────

BUCKET_NAME=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`BucketName`].OutputValue' \
    --output text)

DISTRIBUTION_ID=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`DistributionId`].OutputValue' \
    --output text)

DOMAIN_NAME=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`DistributionDomainName`].OutputValue' \
    --output text)

if [ -z "$BUCKET_NAME" ] || [ -z "$DISTRIBUTION_ID" ] || [ -z "$DOMAIN_NAME" ]; then
    echo "Error: Could not retrieve stack outputs" >&2
    exit 1
fi

# ── Upload content ──────────────────────────────────────────────────────────

echo "Syncing files to s3://$BUCKET_NAME ..." >&2
aws s3 sync "$PROJECT_PATH" "s3://$BUCKET_NAME" \
    --delete \
    --region "$REGION" \
    --exclude '.git/*' \
    --exclude 'node_modules/*' \
    >&2

# ── Invalidate CloudFront cache ────────────────────────────────────────────

echo "Invalidating CloudFront cache..." >&2
aws cloudfront create-invalidation \
    --distribution-id "$DISTRIBUTION_ID" \
    --paths "/*" \
    --region "$REGION" \
    >/dev/null 2>&1

PREVIEW_URL="https://$DOMAIN_NAME"

echo "" >&2
echo "Deployment successful!" >&2
echo "" >&2
echo "Preview URL: $PREVIEW_URL" >&2
echo "Stack:       $STACK_NAME" >&2
echo "Bucket:      $BUCKET_NAME" >&2
echo "Region:      $REGION" >&2
echo "" >&2
echo "To tear down: aws cloudformation delete-stack --stack-name $STACK_NAME --region $REGION" >&2
echo "" >&2

# Output JSON for programmatic use
cat <<EOF
{"previewUrl":"$PREVIEW_URL","distributionId":"$DISTRIBUTION_ID","bucketName":"$BUCKET_NAME","stackName":"$STACK_NAME","region":"$REGION"}
EOF
