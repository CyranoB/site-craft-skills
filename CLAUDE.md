# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Landing Page Builder is a Claude Code skill (plugin) that generates self-contained landing pages from natural-language descriptions and deploys them to Vercel using claimable deployments (no auth required). It's distributed via the Claude Code plugin marketplace and also compatible with OpenCode (which reads `SKILL.md` files from `.claude/skills/` directories).

## Architecture

This is a no-build, no-dependencies project. There is no package.json, no compilation step, and no test framework. The entire skill is defined through markdown instructions and a bash deployment script.

```
.claude-plugin/
├── plugin.json            # Plugin manifest (name, version, description)
└── marketplace.json       # Marketplace catalog entry (owner, keywords, category)
skills/
├── landing-page-builder/
│   ├── SKILL.md               # Workflow + design instructions
│   └── references/web-design-guidelines.md  # Accessibility/UX compliance rules
├── scroll-sequence/
│   ├── SKILL.md               # Workflow, defaults, animation reference
│   └── references/implementation.md  # Full HTML/CSS/JS patterns
├── vercel-deploy/
│   ├── SKILL.md               # Deploy workflow and size guidelines
│   └── scripts/deploy.sh      # Bash script that tars and POSTs to Vercel's deploy API
├── aws-deploy/
│   ├── SKILL.md               # Deploy workflow and prerequisites
│   ├── cloudformation/static-site.yaml  # S3 + CloudFront stack template
│   └── scripts/deploy.sh      # Bash script that provisions and syncs to AWS
└── gcp-deploy/
    ├── SKILL.md               # Deploy workflow and prerequisites
    └── scripts/deploy.sh      # Bash script that deploys to Firebase Hosting
```

**Landing page workflow:** gather context → propose design → generate HTML → deploy via vercel-deploy (or aws-deploy/gcp-deploy)
**Scroll sequence workflow:** verify ffmpeg → analyze video → extract frames → scaffold → build HTML/CSS/JS → test → deploy via vercel-deploy (or aws-deploy/gcp-deploy for full-res)
**AWS deploy workflow:** check AWS CLI + credentials → create/reuse CloudFormation stack → sync to S3 → invalidate CloudFront
**GCP deploy workflow:** check Firebase CLI + login → scaffold firebase.json → deploy to Firebase Hosting

## Key Files

**`SKILL.md` frontmatter** controls when the skill auto-triggers in Claude Code. The `description` field is what Claude uses as trigger keywords — edit it to change when the skill activates. The `name` field must match the directory name.

**`vercel-deploy/scripts/deploy.sh` contract:**
- Takes one argument: path to a directory (or a `.tgz` file)
- Writes status messages to **stderr**; outputs JSON response to **stdout**
- Auto-renames a single non-`index.html` file in the directory to `index.html`
- Returns JSON: `{ previewUrl, claimUrl, deploymentId, projectId }`
- Deploy endpoint: `https://claude-skills-deploy.vercel.com/api/deploy`
- Used by both landing-page-builder and scroll-sequence skills

**`aws-deploy/scripts/deploy.sh` contract:**
- Takes one argument: path to a directory, optional `--region` flag (default: `us-east-1`)
- Writes status messages to **stderr**; outputs JSON response to **stdout**
- Auto-renames a single non-`index.html` file in the directory to `index.html`
- Creates/reuses a CloudFormation stack named `site-craft-<dirname>`
- Returns JSON: `{ previewUrl, distributionId, bucketName, stackName, region }`
- First deploy takes 3-5 min (CloudFront provisioning); subsequent deploys ~10s
- Used by landing-page-builder and scroll-sequence skills as alternative to Vercel

**`gcp-deploy/scripts/deploy.sh` contract:**
- Takes one argument: path to a directory, optional `project-id`
- Writes status messages to **stderr**; outputs JSON response to **stdout**
- Auto-renames a single non-`index.html` file in the directory to `index.html`
- Scaffolds `firebase.json` if missing and deploys to Firebase Hosting
- Returns JSON: `{ hostingUrl, projectId }`
- Used by landing-page-builder and scroll-sequence skills as alternative to Vercel/AWS

**`web-design-guidelines.md`** is referenced by the landing-page-builder skill for accessibility and UX compliance rules. It is not read at install time — only when the skill executes.

## Version Management

Both `plugin.json` and `marketplace.json` have a `"version"` field. Keep them in sync when releasing. The `marketplace.json` `source` field must remain `"./"` (with trailing slash) to pass schema validation.

## Key Design Constraints

- Generated pages must use **distinctive aesthetics** — no generic AI patterns (purple gradients, card grids, Inter/Roboto fonts)
- All HTML must be **accessible**: semantic elements, ARIA labels, keyboard navigation, `prefers-reduced-motion` support
- Pages are **fully self-contained**: single HTML file with inline CSS/JS and Google Fonts via CDN

## Installation & Testing

**Claude Code:**
```
/plugin marketplace add CyranoB/site-craft-skills
/plugin install landing-page-builder@site-craft-skills
```

**OpenCode** (manual file copy — no marketplace command):
```bash
git clone https://github.com/CyranoB/site-craft-skills.git /tmp/site-craft-skills
mkdir -p .claude/skills/landing-page-builder
cp -r /tmp/site-craft-skills/skills/landing-page-builder/* .claude/skills/landing-page-builder/
```

Test the deploy script directly (bypassing the skill):
```bash
mkdir -p /tmp/landing-page
echo '<html><body>test</body></html>' > /tmp/landing-page/index.html
bash skills/vercel-deploy/scripts/deploy.sh /tmp/landing-page
```

To test the full skill workflow, prompt Claude Code with:
```
Build me a landing page for a dog walking app called PawPals
```
