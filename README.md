# Site Craft Skills

A collection of [Claude Code skills](https://docs.anthropic.com/en/docs/claude-code/skills) for generating and deploying polished web experiences from natural-language descriptions.

## Skills

### Landing Page Builder

Generates distinctive landing pages from a text description and deploys them live to Vercel — no authentication required.

1. Takes a natural-language description of a product, service, or idea
2. Generates a self-contained `index.html` with inline CSS/JS
3. Deploys it instantly to Vercel and returns a live preview URL

**Example prompts:**
- "Build me a landing page for a dog walking app called PawPals"
- "Create a website for my SaaS product that does invoice automation"
- "Deploy a landing page for a coffee subscription service, dark luxury aesthetic"

### Scroll Sequence

Turns a video file into a premium scroll-sequence website — the Apple-style experience where scrolling scrubs through video frames with choreographed text animations. Requires `ffmpeg`.

1. Analyzes the video and extracts frames as WebP images
2. Builds a scroll-driven site with canvas rendering, GSAP animations, and Lenis smooth scroll
3. Outputs a portable HTML/CSS/JS project (no build tools)

**Example prompts:**
- "Turn this product video into an Apple-style scroll experience"
- "Build a scroll-sequence site from my demo.mp4"
- "Create a scrollytelling page from this brand film"

## Design philosophy

Every generated page follows an opinionated design approach:

- **No AI slop** — no purple-gradient-on-white, no generic card grids, no cookie-cutter hero sections
- **Bold aesthetics** — each page commits to a specific direction (brutalist, editorial, retro-futuristic, luxury, etc.)
- **Distinctive typography** — characterful Google Fonts pairings, never Inter/Roboto/Arial
- **Production quality** — responsive, accessible, semantic HTML, `prefers-reduced-motion` support

Design guidelines are adapted from [Anthropic's frontend-design skill](https://github.com/anthropics/skills/tree/main/skills/frontend-design) and [Vercel's Web Interface Guidelines](https://github.com/vercel-labs/web-interface-guidelines).

### Vercel Deploy

Deploy any static site directory to Vercel instantly — no authentication, no config. Used by both skills above, or standalone.

**Example prompts:**
- "Deploy this to Vercel"
- "Put this site live"
- "Host this directory"

### AWS Deploy

Deploy any static site to AWS S3 + CloudFront with HTTPS, global CDN, and no size limit. Ideal for scroll-sequence sites with full-resolution frames that exceed Vercel's 4.5MB compressed payload limit. Requires AWS CLI and credentials.

**Example prompts:**
- "Deploy this to AWS"
- "Host this on S3"
- "Put this on CloudFront"
- "Deploy to AWS with no size limit"

### GCP Deploy

Deploy any static site directory to Google Cloud via Firebase Hosting. Professional-grade static hosting with a global CDN and free SSL. Ideal for users with existing GCP projects. Requires Firebase CLI and local authentication.

**Example prompts:**
- "Deploy this to GCP"
- "Host on Google Cloud"
- "Publish to Firebase"
- "Deploy to GCP/Firebase"

## Plugin structure

```
.claude-plugin/
├── plugin.json                                  # Plugin manifest
└── marketplace.json                             # Marketplace catalog
skills/
├── landing-page-builder/
│   ├── SKILL.md                                 # Workflow and design instructions
│   └── references/web-design-guidelines.md      # Accessibility and UX compliance rules
├── scroll-sequence/
│   ├── SKILL.md                                 # Workflow, defaults, and animation reference
│   └── references/implementation.md             # Full HTML/CSS/JS implementation patterns
├── vercel-deploy/
│   ├── SKILL.md                                 # Deploy workflow and size guidelines
│   └── scripts/deploy.sh                        # Vercel claimable deployment (no auth)
└── aws-deploy/
    ├── SKILL.md                                 # Deploy workflow and prerequisites
    ├── cloudformation/static-site.yaml          # S3 + CloudFront stack template
    └── scripts/deploy.sh                        # AWS S3 + CloudFront deployment
```

## Installation

### Claude Code

Add the marketplace and install the plugin from within Claude Code:

```
/plugin marketplace add CyranoB/site-craft-skills
/plugin install landing-page-builder@site-craft-skills
```

### OpenCode

[OpenCode](https://github.com/sst/opencode) natively reads `SKILL.md` files from `.claude/skills/` directories. Clone the repo and copy the skill files into your project:

```bash
git clone https://github.com/CyranoB/site-craft-skills.git /tmp/site-craft-skills

# Landing Page Builder
mkdir -p .claude/skills/landing-page-builder
cp -r /tmp/site-craft-skills/skills/landing-page-builder/* .claude/skills/landing-page-builder/

# Scroll Sequence
mkdir -p .claude/skills/scroll-sequence
cp -r /tmp/site-craft-skills/skills/scroll-sequence/* .claude/skills/scroll-sequence/

# Vercel Deploy (used by both skills above)
mkdir -p .claude/skills/vercel-deploy
cp -r /tmp/site-craft-skills/skills/vercel-deploy/* .claude/skills/vercel-deploy/

# AWS Deploy (alternative to Vercel, no size limit)
mkdir -p .claude/skills/aws-deploy
cp -r /tmp/site-craft-skills/skills/aws-deploy/* .claude/skills/aws-deploy/
```

For a global install (available in all projects):

```bash
mkdir -p ~/.claude/skills/landing-page-builder ~/.claude/skills/scroll-sequence ~/.claude/skills/vercel-deploy ~/.claude/skills/aws-deploy
cp -r /tmp/site-craft-skills/skills/landing-page-builder/* ~/.claude/skills/landing-page-builder/
cp -r /tmp/site-craft-skills/skills/scroll-sequence/* ~/.claude/skills/scroll-sequence/
cp -r /tmp/site-craft-skills/skills/vercel-deploy/* ~/.claude/skills/vercel-deploy/
cp -r /tmp/site-craft-skills/skills/aws-deploy/* ~/.claude/skills/aws-deploy/
```

### Codex CLI

[Codex](https://github.com/openai/codex) discovers skills from `~/.codex/skills/`. Clone the repo:

```bash
git clone https://github.com/CyranoB/site-craft-skills.git ~/.codex/skills/site-craft-skills
```

### Pi Coding Agent

[Pi](https://github.com/badlogic/pi-mono/tree/main/packages/coding-agent) discovers skills from `~/.pi/agent/skills/` or `.pi/skills/` directories. Clone the repo into Pi's skill directory:

```bash
git clone https://github.com/CyranoB/site-craft-skills.git ~/.pi/agent/skills/site-craft-skills
```

For project-level install:

```bash
git clone https://github.com/CyranoB/site-craft-skills.git .pi/skills/site-craft-skills
```

Pi reads `SKILL.md` files from subdirectories automatically — all four skills will be available.

## Credits

Built on top of:
- [frontend-design](https://github.com/anthropics/skills/tree/main/skills/frontend-design) by Anthropic — aesthetic direction and anti-slop principles
- [web-design-guidelines](https://github.com/vercel-labs/agent-skills/tree/main/skills/web-design-guidelines) by Vercel — accessibility and UX compliance rules
- [vercel-deploy-claimable](https://github.com/vercel-labs/agent-skills/tree/main/skills/claude.ai/vercel-deploy-claimable) by Vercel — zero-auth deployment script

## License

MIT
