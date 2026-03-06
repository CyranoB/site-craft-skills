---
name: landing-page-builder
description: Build and deploy polished landing pages and one-page websites to Vercel from a text description. ALWAYS use this skill when a user wants any kind of single-page web presence created and deployed — landing pages, product pages, startup sites, business websites, portfolio sites, event pages, coming soon pages, or promotional pages. This includes when someone describes a business, product, service, or event and wants a live website, even if they say "website" or "site" instead of "landing page." Common triggers include "build me a landing page," "I need a website for my business," "create a page for my product," "make a website for my startup," "deploy a landing page," or describing any business/product/service (like "I have a piano teaching business" or "I run a photography studio" or "we're launching on Kickstarter") and wanting a web presence. Generates a single self-contained HTML file with distinctive, non-generic design and deploys it live to Vercel instantly — no authentication required. Do NOT use for multi-page apps, e-commerce stores, dashboards, documentation sites, blogs, or reviewing/debugging existing code.
---

# Landing Page Builder

Generate a production-quality static landing page from a user's description and deploy it live to Vercel.

## Workflow

### 1. Gather Context

Extract from the user's description:
- **Product/service** — what it does, who it's for
- **Tone** — professional, playful, bold, minimal, luxury, etc.
- **Sections** — hero, features, pricing, testimonials, CTA, footer
- **Brand** — colors, fonts, logo URL if provided

If the description is vague, ask one focused clarifying question. Do not over-interrogate.

### 2. Design

Tell the user: **"Designing your page…"**

#### 2a. Propose a design direction

Analyze the product, target customers, and tone to recommend **one** design direction that best fits. Draw from this aesthetic spectrum:

- Brutally minimal, maximalist chaos, retro-futuristic, organic/natural, luxury/refined, playful/toy-like, editorial/magazine, brutalist/raw, art deco/geometric, soft/pastel, industrial/utilitarian

Present your recommendation with:
- **Name** — a short evocative label (e.g., "Neon Brutalist", "Warm Editorial")
- **Vibe** — one sentence capturing the feel
- **Key choices** — font pairing direction, color palette mood, layout approach

Ask the user to confirm this direction, or say they'd like to see alternatives. If the user wants alternatives, propose **2–3 different directions** to choose from.

#### 2b. Execute the confirmed direction

Once the user confirms, commit to the direction fully and execute with conviction:

**Typography**: Choose distinctive, characterful fonts from Google Fonts. Never default to Inter, Roboto, Arial, or system fonts. Consider using a single font family cohesively (e.g., DM Sans + DM Mono, or a display weight paired with its regular weight) — this often produces more polished results than mixing two unrelated display fonts. Use tight letter-spacing on headings (`-0.02em` to `-0.04em`) for a modern editorial feel. Every landing page should use different fonts — never converge on the same choices.

**Color**: Commit to a cohesive palette. Define all tokens in a `:root` block at the top of your `<style>` tag before writing any other CSS. Every color and spacing value in the stylesheet must reference a token — no hardcoded hex values or magic pixel sizes outside `:root`.

```css
:root {
  /* Color tokens */
  --color-bg: ...;
  --color-surface: ...;
  --color-text: ...;
  --color-text-muted: ...;
  --color-primary: ...;
  --color-accent: ...;
  --color-border: ...;

  /* Scale tokens */
  --radius: ...;
  --space: ...;        /* base unit; use calc(var(--space) * N) for multiples */

  /* Typography tokens */
  --font-display: ...;
  --font-body: ...;
}
```

Dominant colors with sharp accents outperform timid, evenly-distributed palettes. **Light themes are underused and often more distinctive** — warm off-whites, cream, and parchment backgrounds with bold primary colors (deep greens, navy, terracotta) feel fresh and confident. Don't default to dark themes; choose the theme that best serves the brand. A craft cocktail bar might warrant dark and moody, but a freelancer productivity tool might shine on a warm light background with earthy accents. Vary across generations.

**Motion**: Focus on physical, tactile feedback over flashy effects. Subtle `scale(0.97)` on button press feels more polished than a glowing box-shadow. One well-orchestrated page load with staggered reveals (`animation-delay`) creates more delight than scattered micro-interactions. Scroll-triggered fade-ins via `IntersectionObserver` (starting from `opacity: 0; transform: translateY(20px)`) add life without being distracting. CSS-only solutions preferred.

**Layout**: Centered, focused layouts with controlled reading widths (`max-width` on headings and body text) often feel more editorial and intentional than split-column layouts. That said, when the product has a visual demo to show (a terminal, a dashboard, an app screenshot), a two-column hero with the demo alongside the headline is powerful — it tells the product story above the fold. Choose the layout that serves the content, not the one that fills the most space.

**Visual texture**: Gradient meshes, noise textures (SVG filter overlays at low opacity), geometric patterns, layered transparencies, decorative borders, grain overlays. Background texture should be felt more than seen — `opacity: 0.03` to `0.07` is the sweet spot. Avoid empty decorative panels; every visual element should communicate something about the product.

**Anti-slop rule**: The goal is to avoid any aesthetic that reads as "AI-generated template." This includes:
- Purple/violet gradients on white or dark backgrounds
- Teal/cyan neon accents on dark navy (`#0a-#0f` range backgrounds with `#00D4xx` accents) — this is the dark-mode equivalent of purple-on-white
- Card grids where every card looks identical until hovered
- Uppercase section labels with wide letter-spacing ("FEATURES", "HOW IT WORKS")
- Glowing box-shadows on hover (`rgba(primary, 0.3)` blur effects)
- Background glow blobs (large radial gradients floating behind content)
- Floating cards offset from mockups
- Generic social proof numbers that feel inflated

Each page must feel like a human designer made it for this specific business. Ask yourself: "Would a freelance designer be proud to put this in their portfolio?"

**Content realism**: The copy and content should feel grounded and specific, not like marketing filler. Include:
- **Testimonials** with named people, specific quotes, and attribution (platform or role) — these are among the strongest trust signals on any landing page
- **Realistic data** in mockups and demos — if showing an app UI, use specific project names, real-looking numbers, plausible usernames rather than abstract placeholders like "34.5h" or "$4,140"
- **Prices** when the product/service has them — omitting prices when they exist feels evasive
- **Specific details** over vague claims — "Works with Figma, VS Code, and Notion" beats "Integrates with your favorite tools"; "Thursday at 7 PM, $65/person, max 12 people" beats "Weekly classes available"
- **Honest-feeling statistics** — "4,200+ users" feels more credible than "12,000+ users" for an early-stage product

**Icons**: Pick one icon library per page based on the design direction:

| Library | Best for | CDN | Usage |
|---------|----------|-----|-------|
| **Lucide** | Minimal, editorial, refined | `<script src="https://unpkg.com/lucide@latest"></script>` | `<i data-lucide="icon-name"></i>` + `lucide.createIcons()` |
| **Phosphor Icons** | Playful, bold, expressive | `<script src="https://cdn.jsdelivr.net/npm/@phosphor-icons/web@2.1.2"></script>` | `<i class="ph ph-icon-name"></i>` (weights: `ph-thin`, `ph-light`, `ph`, `ph-bold`, `ph-fill`, `ph-duotone`) |
| **Tabler Icons** | Feature-heavy, all-rounder (5,400+ icons) | `<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@latest/tabler-icons.min.css">` | `<i class="ti ti-icon-name"></i>` |

Match the library to the page's aesthetic. Phosphor's weight variants are especially useful for matching typographic weight. Don't litter the page with icons — use them intentionally for feature lists, navigation, or CTAs. A page with 3 well-placed icons beats one with 20 generic ones.

### 3. Build

Tell the user: **"Building your page…"**

Generate a single `index.html` file. All CSS and JS inline. The file must be self-contained and deployable with no build step.

Structure:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="theme-color" content="...">
  <title>...</title>

  <!-- SEO -->
  <meta name="description" content="...">

  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=...&display=swap" rel="stylesheet">
  <style>/* all CSS here */</style>
</head>
<body>
  <!-- semantic HTML -->
  <script>/* animations, interactions */</script>
</body>
</html>
```

Requirements:
- Fully responsive (mobile-first)
- Load Google Fonts via `<link>` with `font-display: swap`
- `<img>` tags need explicit `width`/`height` and `loading="lazy"` below fold
- Honor `prefers-reduced-motion`
- Semantic HTML: `<header>`, `<main>`, `<section>`, `<footer>`, `<nav>`
- Accessible: form labels, `aria-label` on icon buttons, `:focus-visible` states, skip link
- Include Open Graph (`og:title`, `og:description`, `og:type`) and Twitter Card (`twitter:card`, `twitter:title`, `twitter:description`) meta tags when the page is for a publicly shared product or service. Omit them for personal or internal pages, or if the user opts out.
- Include a `<script type="application/ld+json">` block in `<head>` with structured data matching the page content. Use `Organization` for company/startup pages, `Product` for product launches, `LocalBusiness` for local services, or another appropriate schema.org type. Populate `name`, `description`, and `url` (leave `url` empty — it's filled post-deploy).
- For detailed compliance rules, read `references/web-design-guidelines.md`

Write the file to a temporary project directory.

### 4. Deploy

Deploy immediately after generating the HTML.

**Option A — Vercel (default, no auth required):**

```bash
bash skills/vercel-deploy/scripts/deploy.sh <project-directory>
```

If the `vercel-deploy` skill is installed at a different path, look for it at `../vercel-deploy/scripts/deploy.sh` relative to this skill, or in `.claude/skills/vercel-deploy/scripts/`.

**Option B — AWS S3 + CloudFront (when user requests AWS hosting):**

```bash
bash skills/aws-deploy/scripts/deploy.sh <project-directory> [--region us-east-1]
```

Use this when the user explicitly asks to deploy to AWS, host on S3, or deploy to CloudFront. Requires AWS CLI and credentials. First deploy takes 3-5 minutes; subsequent deploys reuse the same stack. If the `aws-deploy` skill is installed at a different path, look for it at `../aws-deploy/scripts/deploy.sh` relative to this skill, or in `.claude/skills/aws-deploy/scripts/`.

**Option C — Google Cloud / Firebase (when user requests GCP hosting):**

```bash
bash skills/gcp-deploy/scripts/deploy.sh <project-directory> [project-id]
```

Use this when the user explicitly asks to deploy to GCP or Firebase. Requires Firebase CLI and local authentication. Firebase Hosting provides a free tier, SSL, and a global CDN. If the `gcp-deploy` skill is installed at a different path, look for it at `../gcp-deploy/scripts/deploy.sh` relative to this skill, or in `.claude/skills/gcp-deploy/scripts/`.

Present results:

```
Your landing page is live!

Preview URL: https://...vercel.app
Claim URL:   https://vercel.com/claim-deployment?code=...

Visit the Preview URL to see your page.
To transfer this deployment to your Vercel account, visit the Claim URL.
```

### Network Error Handling

If deployment fails due to network restrictions, tell the user:

```
Deployment failed due to network restrictions. To fix this:
1. Go to https://claude.ai/settings/capabilities
2. Add *.vercel.com to the allowed domains
3. Try again
```
