---
name: aws-deploy
description: Deploy any static site to AWS S3 + CloudFront with HTTPS, global CDN, and no size limit. Use this skill when the user wants to deploy to AWS, host on S3, deploy to CloudFront, put a site on AWS, or needs to deploy assets that exceed Vercel's 4.5MB limit (e.g., full-resolution scroll-sequence sites). Triggers on "deploy to AWS," "host on S3," "deploy to CloudFront," "put this on AWS," "deploy with no size limit," or any request to host a static site on AWS infrastructure.
---

# AWS Deploy (S3 + CloudFront)

Deploy any static site directory to AWS using S3 for storage and CloudFront for HTTPS delivery. No size limit — deploy full-resolution scroll-sequence sites, large asset directories, or anything that exceeds Vercel's 4.5MB compressed payload limit.

## When to use

- User explicitly requests AWS hosting
- Site assets exceed Vercel's 4.5MB compressed limit (e.g., scroll-sequence sites with 200+ full-res frames)
- User wants a persistent deployment with easy teardown via CloudFormation
- User already has AWS credentials configured

For quick deploys without AWS credentials, use `vercel-deploy` instead.

## Prerequisites

1. **AWS CLI** — the deploy script auto-installs via Homebrew (macOS) or the official installer (Linux) if missing
2. **AWS credentials** — one of:
   - `aws configure` (stores in `~/.aws/credentials`)
   - Environment variables: `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY`
   - AWS SSO: `aws sso login`

## Workflow

### 1. Identify the directory

The user provides a path to a directory containing static files. If they don't specify one, look for the most recently generated project (e.g., `/tmp/landing-page/`, or whatever the upstream skill produced).

The directory must contain an `index.html` at the root. If there's a single `.html` file with a different name, the deploy script renames it automatically.

### 2. Deploy

Run the deploy script:

```bash
bash <skill-path>/scripts/deploy.sh <directory> [--region <region>]
```

- Default region: `us-east-1` (override with `--region` or `AWS_REGION` env var)
- First deploy creates a CloudFormation stack (takes 3-5 minutes for CloudFront distribution)
- Subsequent deploys to the same directory name reuse the existing stack (just syncs files, ~10 seconds)

The script:
- Creates a CloudFormation stack named `site-craft-<directory-name>` with S3 bucket, CloudFront distribution, and OAC
- Syncs the directory contents to S3
- Invalidates the CloudFront cache
- Returns JSON with `previewUrl`, `distributionId`, `bucketName`, `stackName`, `region`

### 3. Present results

Tell the user:

```
Your site is live on AWS!

Preview URL: https://<id>.cloudfront.net
Stack:       site-craft-<name>
Region:      us-east-1

First-time deploys take 3-5 minutes (CloudFront distribution provisioning).
Subsequent deploys update in ~10 seconds + cache invalidation time.
```

### 4. Cleanup

To tear down all resources for a deployment, empty the bucket first (CloudFormation can't delete a non-empty S3 bucket), then delete the stack.

Find the bucket name from the stack outputs:

```bash
aws cloudformation describe-stacks --stack-name site-craft-<name> --region us-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`BucketName`].OutputValue' --output text
```

Then empty and delete:

```bash
aws s3 rm s3://<bucket-name> --recursive --region us-east-1
aws cloudformation delete-stack --stack-name site-craft-<name> --region us-east-1
```

This deletes the S3 bucket, CloudFront distribution, and all associated resources.

## First-time setup

On the very first deploy, the script:
1. Creates a CloudFormation stack with 4 resources (S3 bucket, CloudFront distribution, OAC, bucket policy)
2. Waits for CloudFront distribution provisioning (~3-5 minutes)
3. Uploads content and invalidates cache

Subsequent deploys to the same site skip stack creation and just sync files.

## Minimal IAM policy

For users who want to scope down permissions, this is the minimum policy needed:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudformation:CreateStack",
        "cloudformation:DeleteStack",
        "cloudformation:DescribeStacks",
        "cloudformation:DescribeStackEvents"
      ],
      "Resource": "arn:aws:cloudformation:*:*:stack/site-craft-*/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket",
        "s3:DeleteBucket",
        "s3:PutBucketPolicy",
        "s3:DeleteBucketPolicy",
        "s3:PutBucketEncryption",
        "s3:PutBucketPublicAccessBlock",
        "s3:GetBucketPolicy",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::site-craft-*",
        "arn:aws:s3:::site-craft-*/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudfront:CreateDistribution",
        "cloudfront:DeleteDistribution",
        "cloudfront:GetDistribution",
        "cloudfront:UpdateDistribution",
        "cloudfront:CreateInvalidation",
        "cloudfront:CreateOriginAccessControl",
        "cloudfront:DeleteOriginAccessControl",
        "cloudfront:GetOriginAccessControl",
        "cloudfront:TagResource"
      ],
      "Resource": "*"
    }
  ]
}
```
