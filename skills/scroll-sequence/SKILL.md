---
name: scroll-sequence
description: Turn a video file into a premium scroll-sequence website — the Apple-style experience where scrolling scrubs through video frames with choreographed text animations. Use this skill whenever the user provides a video file (MP4, MOV, WebM, etc.) and wants it turned into a scroll-sequence site, scroll-driven landing page, or scrollytelling experience. Also triggers when the user mentions "scroll sequence," "scrollytelling," "scroll-driven animation," "video frames on scroll," "Apple-style scroll animation," "frame-by-frame scroll," or wants a product reveal site built from video footage. If the user has a product video, demo reel, or any footage they want presented as a polished scroll-sequence web experience rather than just an embedded video player, this is the skill to use.
---

# Video to Premium Scroll-Driven Website

Turn a video file into a scroll-driven animated website with **animation variety and choreography** — multiple animation types working together, not one repeated effect.

The result is a website where scrolling controls video playback frame-by-frame on a canvas, with text sections animating in from different directions as the user scrolls. Think Apple product pages, but generated from any video — product demos, brand films, nature footage, music videos, or anything visual.

## Scope

**This skill does:**
- Extract frames from a video and build a scroll-driven single-page site
- Generate HTML, CSS, and JS with no build tools (vanilla + CDN)
- Handle product/brand sites, editorial pages, artistic showcases

**This skill does not:**
- Edit or trim the source video
- Add audio/sound sync
- Build multi-page sites, dashboards, or e-commerce stores

## Input

The user provides a video file path (MP4, MOV, WebM, etc.) and optionally:
- A theme/brand name
- Desired text sections and where they appear
- Color scheme preferences
- Any specific design direction (commercial product page, editorial, artistic)

If the user doesn't specify these, ask briefly or use sensible creative defaults.

## Premium Defaults

These are strong defaults backed by visual reasoning. Each solves a specific problem. **If the user explicitly requests something different, follow their preference** — they know their context better.

1. **Lenis smooth scroll** — native browser scroll feels jerky during frame playback; Lenis provides the buttery interpolation that makes canvas animation feel intentional
2. **4+ animation types** — repeating the same entrance animation makes sections feel templated; variety creates the impression each section was hand-crafted
3. **Staggered reveals** — label then heading then body then CTA; simultaneous entrance looks like a flash, staggering guides the eye through a reading hierarchy
4. **No glassmorphism cards** — frosted-glass effects over video frames create visual noise; clean backgrounds with typographic hierarchy let the video breathe
5. **Direction variety** — sections entering from different directions (left, right, up, scale, clip) create spatial depth; same-direction entrances feel flat
6. **Dark overlay for stats** — statistics need high contrast to read over moving frames; 0.88-0.92 opacity overlay with animated counters. This is the one context where centered text works
7. **Horizontal text marquee** — at least one oversized text element (12vw+) sliding on scroll; this breaks the vertical rhythm and creates visual surprise
8. **Counter animations** — numbers count up from 0 on scroll; static numbers feel dead next to animated video frames
9. **Massive typography** — hero 12rem+, section headings 4rem+, marquee 10vw+; at these sizes type becomes a design element, not just text
10. **CTA persists** — `data-persist="true"` keeps the final section visible after it animates in
11. **Hero prominence + generous scroll** — hero gets 20%+ scroll range, 800vh+ total for 6 sections; cramped scroll ranges make animations feel rushed
12. **Side-aligned text** — text in outer 40% zones (`align-left`/`align-right`) so the video occupies the viewport center without competition. Exception: stats with full dark overlay
13. **Circle-wipe hero reveal** — hero is a standalone 100vh section; the canvas reveals via expanding `clip-path: circle()` as the hero scrolls away
14. **Frame speed 1.8-2.2** — the video completes by ~55% scroll, leaving room for content sections

## Workflow

### Step 1: Verify Dependencies

```bash
which ffmpeg && which ffprobe
```

If not found, tell the user to install ffmpeg before proceeding.

### Step 2: Analyze the Video

```bash
ffprobe -v error -select_streams v:0 -show_entries stream=width,height,duration,r_frame_rate,nb_frames -of csv=p=0 "<VIDEO_PATH>"
```

Determine resolution, duration, frame rate, total frames. Decide:
- **Target frame count**: 150-300 frames for good scroll experience
  - Short video (<10s): extract at original fps, cap at ~300
  - Medium (10-30s): extract at 10-15fps
  - Long (30s+): extract at 5-10fps
- **Output resolution**: Match aspect ratio, cap width at 1920px
- **File size check**: At 80% webp quality, budget ~30-80KB per frame. 300 frames at 1920px wide runs ~15-25MB total. If the video would produce 40MB+, reduce resolution to 1280px or cut frame count to stay under that.

### Step 3: Extract Frames

```bash
mkdir -p frames
ffmpeg -i "<VIDEO_PATH>" -vf "fps=<CALCULATED_FPS>,scale=<WIDTH>:-1" -c:v libwebp -quality 80 "frames/frame_%04d.webp"
```

After extraction, verify the count: `ls frames/ | wc -l`

### Step 4: Scaffold

Create an output directory named after the project (e.g., the brand name, or `video-site` as fallback):

```
<project-name>/
  index.html
  css/style.css
  js/app.js
  frames/frame_0001.webp ...
```

No bundler. Vanilla HTML/CSS/JS + CDN libraries. This keeps it portable and zero-config.

### Step 5: Build index.html

Required `<head>` content:

```html
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="description" content="[PROJECT_DESCRIPTION]">
<meta property="og:title" content="[PROJECT_NAME]">
<meta property="og:description" content="[PROJECT_DESCRIPTION]">
<link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><text y='.9em' font-size='90'>EMOJI</text></svg>">
<link rel="preconnect" href="https://fonts.googleapis.com">
```

Required `<body>` structure (in this order):

```
1. Loader        — #loader > .loader-brand, #loader-bar-track > #loader-bar, #loader-percent
2. Fixed header  — .site-header > nav with logo + links
3. Hero          — .hero-standalone (100vh, solid bg, word-split heading)
4. Canvas        — .canvas-wrap > canvas#canvas (fixed, full viewport)
5. Dark overlay  — #dark-overlay (fixed, full viewport, pointer-events:none)
6. Marquee(s)    — .marquee-wrap > .marquee-text (fixed, 12vw font)
7. Scroll container — #scroll-container (800vh+)
     Content sections with data-enter, data-leave, data-animation
     Stats section with .stat-number[data-value][data-decimals]
     CTA section with data-persist="true"
```

Read `references/implementation.md` for HTML templates (content sections, stats sections, CDN script tags).

### Step 6: Build css/style.css

Key concerns:
- **Side-aligned text zones**: `.align-left` and `.align-right` keep text in the outer 40%, leaving center for video
- **Scroll sections**: `position: absolute` within scroll container, positioned at midpoint of enter/leave range
- **Text contrast over video**: Text floats over canvas frames that can be any brightness. Two rules:
  1. **Nearly-opaque panel**: Always add `background: rgba(0,0,0,0.92) !important` on `.section-inner`. The `!important` is needed because GSAP's inline style cascade can interfere. This reads as a solid dark card with just a hint of the video at the edges. Subtle scrims (0.5-0.8) are NOT enough — video frames are busy and bright.
  2. **No opacity reduction on text**: Do NOT set `opacity` below 0.85 on `.section-label`, `.section-body`, or `.section-note`. These elements sit over video — reducing opacity makes them gray and invisible on bright frames. Use `color` values for hierarchy instead (e.g. `#fff` for headings, `#ddd` for body, `#aaa` for labels).
- **Font and color choices**: Be creative and distinctive, complement the video content

Read `references/implementation.md` (CSS Patterns section) for the full CSS including mobile breakpoints.

### Step 7: Build js/app.js

The JavaScript has 9 components. Read `references/implementation.md` for the complete code. Here's what each does and why:

| Component | Purpose |
|-----------|---------|
| **Lenis setup** | Smooth scroll interpolation — mandatory for frame playback to feel good |
| **Frame preloader** | Two-phase: 10 frames fast, then the rest. Shows progress bar. |
| **Canvas renderer** | Padded cover mode (IMAGE_SCALE 0.82-0.90) with background color sampled from frame edges |
| **Frame-to-scroll binding** | Maps scroll progress to frame index with FRAME_SPEED acceleration |
| **Section animations** | Reads `data-animation` attribute, plays entrance on enter, reverses on leave (unless persist) |
| **Counter animations** | Numbers count up from 0 using GSAP snap |
| **Marquee** | Horizontal sliding text with scroll-linked fade in/out |
| **Dark overlay** | Fades to 0.9 opacity over the stats section range |
| **Circle-wipe** | Expands clip-path circle to reveal canvas as hero scrolls away |

### Step 8: Test

1. Serve locally: `npx serve .` or `python3 -m http.server 8000`
2. Scroll through fully — verify each section has a DIFFERENT animation type
3. Confirm: smooth scroll, frame playback, staggered reveals, marquee slides, counters count up, dark overlay fades, CTA persists at end

### Step 9: Deploy (optional)

If the user wants the site live, use the `vercel-deploy` skill:

```bash
bash skills/vercel-deploy/scripts/deploy.sh <project-directory>
```

Vercel's deploy endpoint has a ~4.5MB compressed payload limit. Full-resolution scroll-sequence sites (1920px, 200 frames) typically exceed this. Before deploying, re-extract frames at deploy-friendly resolution:
```bash
ffmpeg -y -i video.mp4 -vf "fps=12,scale=960:-1" -c:v libwebp -quality 65 frames/frame_%04d.webp
```
Then update `FRAME_COUNT` in `js/app.js` to match. A typical 8s video at 960px/12fps = ~96 frames, ~2MB compressed.

## Mobile Considerations

Mobile is where scroll-driven video sites break hardest. Pay attention to:

- **Memory**: Mobile browsers aggressively kill tabs using too much memory. Cap frames at 150 and resolution at 1280px wide for mobile. Consider using `matchMedia` to load fewer frames on small screens.
- **Touch vs. wheel**: Lenis handles touch events, but test that scroll feels smooth on iOS Safari (which has its own momentum scrolling). `smoothTouch: true` can help.
- **Layout**: Collapse side-aligned text to full-width centered with a dark backdrop behind it (so text reads over the video). See the mobile CSS in `references/implementation.md`.
- **Scroll height**: Reduce from 800vh+ to ~550vh — mobile users scroll faster and have less patience for long pages.
- **Typography**: Scale down massively — hero to ~3rem, headings to ~2rem. The desktop sizes will overflow on small screens.

## Animation Types Quick Reference

| Type | Initial State | Animate To | Duration |
|------|--------------|-----------|----------|
| `fade-up` | y:50, opacity:0 | y:0, opacity:1 | 0.9s |
| `slide-left` | x:-80, opacity:0 | x:0, opacity:1 | 0.9s |
| `slide-right` | x:80, opacity:0 | x:0, opacity:1 | 0.9s |
| `scale-up` | scale:0.85, opacity:0 | scale:1, opacity:1 | 1.0s |
| `rotate-in` | y:40, rot:3, opacity:0 | y:0, rot:0, opacity:1 | 0.9s |
| `stagger-up` | y:60, opacity:0 | y:0, opacity:1 | 0.8s |
| `clip-reveal` | clipPath:inset(100% 0 0 0) | clipPath:inset(0%) | 1.2s |

All use stagger (0.1-0.15s). Easing: `power3.out` (scale-up: `power2.out`, clip-reveal: `power4.inOut`).

## Scroll Range Planning

With `FRAME_SPEED: 2.0`, the video finishes around 50-55% scroll. Content sections should be distributed across the full scroll range — some overlap with active video playback, some appear after the video freezes on its last frame.

**Formula for N content sections** (excludes the hero, which is a standalone element):

| Zone | Scroll range | Purpose |
|------|-------------|---------|
| Hero reveal | 0-7% | Hero fades out, circle-wipe reveals canvas |
| Video-active sections | 8-55% | Sections animate over moving video |
| Video-frozen sections | 55-100% | Sections animate over the final frame |

Within each zone, divide evenly with ~2% gaps between sections. Each section needs at least 8% range for animations to breathe.

**Example for 6 sections:**

| Section | enter | leave | animation | alignment |
|---------|-------|-------|-----------|-----------|
| 1 (intro) | 10 | 24 | slide-left | align-left |
| 2 (feature) | 26 | 40 | slide-right | align-right |
| 3 (feature) | 42 | 54 | fade-up | align-left |
| 4 (stats) | 56 | 72 | stagger-up | (centered, dark overlay) |
| 5 (detail) | 74 | 86 | scale-up | align-right |
| 6 (CTA) | 88 | 100 | clip-reveal | align-left, persist |

Dark overlay `enter`/`leave` should match the stats section range (here: 0.56 to 0.72).

**Quick rules:**
- Hero gets scroll range via the circle-wipe (0-7%), not `data-enter`/`data-leave`
- Never less than 8% range per section
- Never repeat the same `data-animation` on consecutive sections
- Alternate `align-left` / `align-right` (except stats, which are centered)
- Last section: `data-persist="true"`

## Anti-Patterns

- **Cycling feature cards in a pinned section** — each card gets too little scroll time. Give each feature its own section (8-10% scroll range) with its own animation type
- **Pure cover mode** (scale at 1.0) — clips into header. Use IMAGE_SCALE 0.82-0.90
- **Pure contain mode** — leaves visible border. Padded cover + bg sampling solves this
- **FRAME_SPEED < 1.8** — video feels sluggish; use 1.8-2.2
- **Hero < 20% scroll range** — first impression needs breathing room
- **Same animation on consecutive sections** — never repeat the same entrance type back-to-back
- **Text without a nearly-opaque backdrop over video** — video frames are busy and bright; even `rgba(0,0,0,0.78)` is too transparent. Use `rgba(0,0,0,0.92)` on `.section-inner` so it reads as a solid dark card. Never use gradients that fade below 0.9. Never reduce text `opacity` below 0.85 — use `color` values for hierarchy instead
- **Wide centered grids over canvas** — redesign as vertical lists in the 40% side zone
- **Scroll height < 800vh** for 6 sections — everything feels rushed

## Clip-Path Variations

Beyond the default circle-wipe, other reveal options:
- Wipe from left: `inset(0 100% 0 0)` -> `inset(0 0% 0 0)`
- Wipe from bottom: `inset(100% 0 0 0)` -> `inset(0% 0 0 0)`
- Diamond: `polygon(50% 0%, 50% 0%, 50% 100%, 50% 100%)` -> `polygon(0% 0%, 100% 0%, 100% 100%, 0% 100%)`

## Accessibility

- **`prefers-reduced-motion`**: CSS in `references/implementation.md` disables animations and clip-paths when this media query matches. In JS, also check it to skip Lenis and show all sections immediately:
  ```js
  const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  if (reducedMotion) {
    // Skip Lenis, show all sections, display frames as a static image
    document.querySelectorAll(".scroll-section").forEach(s => { s.style.opacity = 1; s.style.position = "relative"; });
  }
  ```
- **Semantic HTML**: Use `<header>`, `<main>`, `<section>`, `<footer>` — not all `<div>`s
- **Alt text**: Add `aria-label` to the canvas element describing the video content
- **Focus visibility**: Ensure CTA buttons and nav links have visible `:focus-visible` outlines

## Troubleshooting

- **Text scrim not visible / text unreadable over video**: The `#scroll-container` needs `z-index: 8` (or higher than `.canvas-wrap` at z-index 5). Without it, the fixed canvas covers the scroll sections and the scrim background is invisible even though it's in the CSS.
- **Frames not loading**: Must serve via HTTP, not `file://`
- **Choppy scrolling**: Increase `scrub` value, reduce frame count
- **White flashes**: Ensure all frames loaded before hiding loader
- **Blurry canvas**: Apply `devicePixelRatio` scaling to canvas dimensions
- **Lenis conflicts**: Ensure `lenis.on("scroll", ScrollTrigger.update)` is connected
- **Counters not animating**: Verify `data-value` attribute exists and snap matches decimal places
- **Memory issues on mobile**: Reduce frames to <150, resize to 1280px wide
