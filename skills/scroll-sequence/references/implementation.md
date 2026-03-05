# Implementation Reference

Complete code patterns for the video-to-website skill. Read this file when building the JS and HTML — it contains the full implementations including functions only described in SKILL.md.

## Table of Contents

1. [HTML Templates](#html-templates)
2. [CSS Patterns](#css-patterns)
3. [Lenis Smooth Scroll](#lenis-smooth-scroll)
4. [Frame Preloader](#frame-preloader)
5. [Canvas Renderer + Background Sampling](#canvas-renderer)
6. [Frame-to-Scroll Binding](#frame-to-scroll-binding)
7. [Section Animation System (with persist)](#section-animation-system)
8. [Counter Animations](#counter-animations)
9. [Horizontal Text Marquee](#horizontal-text-marquee)
10. [Dark Overlay](#dark-overlay)
11. [Circle-Wipe Hero Reveal](#circle-wipe-hero-reveal)

---

## HTML Templates

Content section:
```html
<section class="scroll-section section-content align-left"
         data-enter="22" data-leave="38" data-animation="slide-left">
  <div class="section-inner">
    <span class="section-label">002 / Feature</span>
    <h2 class="section-heading">Feature Headline</h2>
    <p class="section-body">Description text here.</p>
  </div>
</section>
```

Stats section:
```html
<section class="scroll-section section-stats"
         data-enter="54" data-leave="72" data-animation="stagger-up">
  <div class="stats-grid">
    <div class="stat">
      <span class="stat-number" data-value="24" data-decimals="0">0</span>
      <span class="stat-suffix">hrs</span>
      <span class="stat-label">Cold retention</span>
    </div>
  </div>
</section>
```

Loader:
```html
<div id="loader">
  <span class="loader-brand">BRAND NAME</span>
  <div id="loader-bar-track"><div id="loader-bar"></div></div>
  <span id="loader-percent">0%</span>
</div>
```

CDN scripts (end of body, this exact order):
```html
<script src="https://cdn.jsdelivr.net/npm/lenis@1.1/dist/lenis.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/gsap@3.12/dist/gsap.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/gsap@3.12/dist/ScrollTrigger.min.js"></script>
<script src="js/app.js"></script>
```

---

## CSS Patterns

```css
:root {
  --bg-light: #f5f3f0;
  --bg-dark: #111111;
  --text-on-light: #1a1a1a;
  --text-on-dark: #f0ede8;
  --font-display: '[DISPLAY FONT]', sans-serif;
  --font-body: '[BODY FONT]', sans-serif;
}

* { margin: 0; padding: 0; box-sizing: border-box; }
html, body { background: var(--bg-dark); color: var(--text-on-dark); font-family: var(--font-body); overflow-x: hidden; }

/* --- Loader --- */
#loader {
  position: fixed; inset: 0; z-index: 9999;
  display: flex; flex-direction: column; align-items: center; justify-content: center;
  background: var(--bg-dark);
}
.loader-brand { font-family: var(--font-display); font-size: 1.5rem; letter-spacing: 0.1em; margin-bottom: 2rem; }
#loader-bar-track { width: 200px; height: 2px; background: rgba(255,255,255,0.15); border-radius: 1px; overflow: hidden; }
#loader-bar { height: 100%; width: 0%; background: var(--text-on-dark); transition: width 0.15s ease; }
#loader-percent { font-family: var(--font-body); font-size: 0.85rem; margin-top: 0.75rem; opacity: 0.6; }

/* --- Header --- */
.site-header {
  position: fixed; top: 0; left: 0; right: 0; z-index: 100;
  display: flex; align-items: center; justify-content: space-between;
  padding: 1.25rem 3vw; mix-blend-mode: difference;
}
.site-header .logo { font-family: var(--font-display); font-size: 1rem; letter-spacing: 0.08em; color: #fff; text-decoration: none; }
.site-header nav a { color: #fff; text-decoration: none; font-size: 0.85rem; margin-left: 2rem; opacity: 0.7; transition: opacity 0.2s; }
.site-header nav a:hover { opacity: 1; }

/* --- Hero (standalone, before canvas) --- */
.hero-standalone {
  position: fixed; inset: 0; z-index: 10;
  display: flex; flex-direction: column; align-items: center; justify-content: center;
  text-align: center; padding: 0 5vw;
  background: var(--bg-dark);
}
.hero-heading {
  font-family: var(--font-display); font-size: clamp(3rem, 12vw, 12rem);
  line-height: 0.95; letter-spacing: -0.03em; text-transform: uppercase;
}
.hero-sub { font-size: 1.1rem; margin-top: 1.5rem; opacity: 0.6; max-width: 28ch; }

/* --- Canvas --- */
.canvas-wrap {
  position: fixed; inset: 0; z-index: 5;
  clip-path: circle(0% at 50% 50%); /* revealed by JS */
}
.canvas-wrap canvas { display: block; width: 100%; height: 100%; }

/* --- Dark overlay (stats sections) --- */
#dark-overlay {
  position: fixed; inset: 0; z-index: 6;
  background: var(--bg-dark); opacity: 0; pointer-events: none;
}

/* --- Marquee --- */
.marquee-wrap {
  position: fixed; z-index: 7;
  top: 50%; left: 0; width: 100%;
  transform: translateY(-50%); opacity: 0; pointer-events: none;
  overflow: visible; white-space: nowrap;
}
.marquee-text {
  font-family: var(--font-display); font-size: 12vw;
  text-transform: uppercase; letter-spacing: -0.02em;
  color: var(--text-on-dark); opacity: 0.12;
  display: inline-block;
}

/* --- Scroll container --- */
/* z-index must be higher than .canvas-wrap (z-index:5) so sections
   and their dark scrims render ON TOP of the video canvas. Without this,
   the fixed canvas covers the scroll sections and the scrim is invisible. */
#scroll-container { position: relative; z-index: 8; height: 800vh; }

/* --- Scroll sections (shared) --- */
.scroll-section {
  position: absolute; left: 0; width: 100%;
  display: flex; align-items: center;
  opacity: 0; pointer-events: none; z-index: 8;
  transform: translateY(-50%); /* center on its top value */
}
/* Nearly-opaque dark panel behind text. Video frames can be extremely bright
   and busy — a subtle scrim is not enough. 0.92 makes the text panel read as
   a solid dark card while still letting a hint of the frame show at the edges.
   !important is needed because GSAP animations can interfere with backgrounds
   via inline style cascading — this guarantees the scrim is always visible. */
.section-inner {
  display: flex; flex-direction: column; gap: 0.75rem;
  background: rgba(0, 0, 0, 0.92) !important;
  padding: 2rem 2.25rem; border-radius: 12px;
}
/* Text inside scroll sections sits over video via the scrim.
   Do NOT reduce opacity on these elements — the scrim handles contrast.
   Lowering opacity makes text gray/invisible over bright frames. */
.section-label {
  font-family: var(--font-body); font-size: 0.75rem;
  text-transform: uppercase; letter-spacing: 0.15em; opacity: 0.85;
}
.section-heading {
  font-family: var(--font-display); font-size: clamp(2rem, 4vw, 4.5rem);
  line-height: 1.05; letter-spacing: -0.02em; color: #fff;
}
.section-body { font-size: 1.05rem; line-height: 1.65; opacity: 0.92; max-width: 38ch; }
.section-note { font-size: 0.85rem; opacity: 0.7; font-style: italic; }

/* Side-aligned text zones -- product occupies center */
.align-left { padding-left: 5vw; padding-right: 55vw; }
.align-right { padding-left: 55vw; padding-right: 5vw; }
.align-left .section-inner,
.align-right .section-inner { max-width: 40vw; }

/* --- Stats section --- */
.section-stats { justify-content: center; text-align: center; padding: 0 5vw; }
.stats-grid { display: flex; gap: 4rem; flex-wrap: wrap; justify-content: center; }
.stat { display: flex; flex-direction: column; align-items: center; }
.stat-number {
  font-family: var(--font-display); font-size: clamp(2.5rem, 5vw, 5rem);
  line-height: 1; letter-spacing: -0.02em;
}
.stat-suffix { font-family: var(--font-display); font-size: 1.5rem; opacity: 0.7; }
.stat-label { font-size: 0.8rem; text-transform: uppercase; letter-spacing: 0.1em; opacity: 0.5; margin-top: 0.5rem; }

/* --- CTA button --- */
.cta-button {
  display: inline-block; padding: 1rem 2.5rem;
  font-family: var(--font-body); font-size: 0.95rem; font-weight: 600;
  text-decoration: none; text-transform: uppercase; letter-spacing: 0.08em;
  border: 2px solid var(--text-on-dark); color: var(--text-on-dark);
  background: transparent; cursor: pointer;
  transition: background 0.25s, color 0.25s;
}
.cta-button:hover { background: var(--text-on-dark); color: var(--bg-dark); }

/* --- Focus visibility --- */
.cta-button:focus-visible,
.site-header nav a:focus-visible,
.site-header .logo:focus-visible {
  outline: 2px solid var(--text-on-dark);
  outline-offset: 3px;
}

/* --- Reduced motion --- */
@media (prefers-reduced-motion: reduce) {
  .marquee-text, .scroll-section, .stat-number { transition: none !important; animation: none !important; }
  .canvas-wrap { clip-path: none !important; }
  .hero-standalone { position: relative; }
  #scroll-container { height: auto; }
}

/* --- Mobile (<768px) --- */
@media (max-width: 767px) {
  .align-left,
  .align-right {
    padding-left: 5vw;
    padding-right: 5vw;
  }
  .align-left .section-inner,
  .align-right .section-inner {
    max-width: 100%;
    text-align: center;
  }

  .scroll-section .section-inner {
    background: rgba(0, 0, 0, 0.95) !important;
    padding: 1.5rem;
    border-radius: 8px;
  }

  #scroll-container { height: 550vh; }

  .hero-heading { font-size: 3rem; }
  .section-heading { font-size: 2rem; }
  .marquee-text { font-size: 8vw; }
  .stats-grid { gap: 2rem; }
  .site-header { padding: 1rem 4vw; }
  .site-header nav a { margin-left: 1rem; font-size: 0.8rem; }
}
```

---

## Lenis Smooth Scroll

```js
const lenis = new Lenis({
  duration: 1.2,
  easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t)),
  smoothWheel: true
});
lenis.on("scroll", ScrollTrigger.update);
gsap.ticker.add((time) => lenis.raf(time * 1000));
gsap.ticker.lagSmoothing(0);
```

---

## Frame Preloader

Two-phase loading for fast first paint:

```js
const FRAME_COUNT = /* set from extracted frame count */;
const frames = new Array(FRAME_COUNT);
let loadedCount = 0;

function loadFrame(index) {
  return new Promise((resolve) => {
    const img = new Image();
    img.onload = () => {
      frames[index] = img;
      loadedCount++;
      updateLoaderUI(loadedCount, FRAME_COUNT);
      resolve();
    };
    img.onerror = () => resolve(); // skip broken frames
    img.src = `frames/frame_${String(index + 1).padStart(4, "0")}.webp`;
  });
}

async function preloadFrames() {
  // Phase 1: first 10 frames for immediate display
  const firstBatch = Array.from({ length: Math.min(10, FRAME_COUNT) }, (_, i) => loadFrame(i));
  await Promise.all(firstBatch);

  // Draw first frame immediately so user sees something
  drawFrame(0);

  // Phase 2: remaining frames in background
  const remaining = Array.from(
    { length: FRAME_COUNT - 10 },
    (_, i) => loadFrame(i + 10)
  );
  await Promise.all(remaining);

  // All frames ready -- hide loader
  document.getElementById("loader").style.display = "none";
}

function updateLoaderUI(loaded, total) {
  const pct = Math.round((loaded / total) * 100);
  document.getElementById("loader-percent").textContent = pct + "%";
  document.getElementById("loader-bar").style.width = pct + "%";
}
```

---

## Canvas Renderer

Includes the `sampleBgColor()` function for seamless edge blending:

```js
const canvas = document.getElementById("canvas");
const ctx = canvas.getContext("2d");
const IMAGE_SCALE = 0.85; // 0.82-0.90 sweet spot
let bgColor = "#111111"; // default, updated by sampling

// Resize canvas to viewport with devicePixelRatio for crisp rendering
function resizeCanvas() {
  const dpr = window.devicePixelRatio || 1;
  canvas.width = window.innerWidth * dpr;
  canvas.height = window.innerHeight * dpr;
  canvas.style.width = window.innerWidth + "px";
  canvas.style.height = window.innerHeight + "px";
  ctx.scale(dpr, dpr);
}
window.addEventListener("resize", resizeCanvas);
resizeCanvas();

// Sample background color from frame edge pixels using a tiny offscreen canvas.
// Drawing the full image at 4x4 is much cheaper than at full resolution.
// Call every ~20 frames to adapt to changing video content.
const sampleCanvas = document.createElement("canvas");
const sampleCtx = sampleCanvas.getContext("2d", { willReadFrequently: true });
sampleCanvas.width = 4;
sampleCanvas.height = 4;

function sampleBgColor(img) {
  sampleCtx.drawImage(img, 0, 0, 4, 4);
  const corners = [
    sampleCtx.getImageData(0, 0, 1, 1).data,
    sampleCtx.getImageData(3, 0, 1, 1).data,
    sampleCtx.getImageData(0, 3, 1, 1).data,
    sampleCtx.getImageData(3, 3, 1, 1).data,
  ];

  const avg = [0, 0, 0];
  corners.forEach(c => { avg[0] += c[0]; avg[1] += c[1]; avg[2] += c[2]; });
  bgColor = `rgb(${Math.round(avg[0] / 4)}, ${Math.round(avg[1] / 4)}, ${Math.round(avg[2] / 4)})`;
}

function drawFrame(index) {
  const img = frames[index];
  if (!img) return;

  // Re-sample background color every 20 frames
  if (index % 20 === 0) sampleBgColor(img);

  const cw = canvas.width, ch = canvas.height;
  const dpr = window.devicePixelRatio || 1;
  const vw = cw / dpr, vh = ch / dpr;
  const iw = img.naturalWidth, ih = img.naturalHeight;
  const scale = Math.max(vw / iw, vh / ih) * IMAGE_SCALE;
  const dw = iw * scale, dh = ih * scale;
  const dx = (vw - dw) / 2, dy = (vh - dh) / 2;

  ctx.fillStyle = bgColor;
  ctx.fillRect(0, 0, vw, vh);
  ctx.drawImage(img, dx, dy, dw, dh);
}
```

---

## Frame-to-Scroll Binding

```js
const FRAME_SPEED = 2.0; // 1.8-2.2, higher = video finishes earlier in scroll
let currentFrame = 0;

ScrollTrigger.create({
  trigger: scrollContainer,
  start: "top top",
  end: "bottom bottom",
  scrub: true,
  onUpdate: (self) => {
    const accelerated = Math.min(self.progress * FRAME_SPEED, 1);
    const index = Math.min(Math.floor(accelerated * FRAME_COUNT), FRAME_COUNT - 1);
    if (index !== currentFrame) {
      currentFrame = index;
      requestAnimationFrame(() => drawFrame(currentFrame));
    }
  }
});
```

---

## Section Animation System

Includes the full persist logic — sections with `data-persist="true"` animate in but never reverse out:

```js
function setupSectionAnimation(section) {
  const type = section.dataset.animation;
  const persist = section.dataset.persist === "true";
  const enter = parseFloat(section.dataset.enter) / 100;
  const leave = parseFloat(section.dataset.leave) / 100;
  const mid = (enter + leave) / 2;
  const children = section.querySelectorAll(
    ".section-label, .section-heading, .section-body, .section-note, .cta-button, .stat"
  );

  // Position section at midpoint of its scroll range
  section.style.top = (mid * 100) + "%";

  const tl = gsap.timeline({ paused: true });

  switch (type) {
    case "fade-up":
      tl.from(children, { y: 50, opacity: 0, stagger: 0.12, duration: 0.9, ease: "power3.out" });
      break;
    case "slide-left":
      tl.from(children, { x: -80, opacity: 0, stagger: 0.14, duration: 0.9, ease: "power3.out" });
      break;
    case "slide-right":
      tl.from(children, { x: 80, opacity: 0, stagger: 0.14, duration: 0.9, ease: "power3.out" });
      break;
    case "scale-up":
      tl.from(children, { scale: 0.85, opacity: 0, stagger: 0.12, duration: 1.0, ease: "power2.out" });
      break;
    case "rotate-in":
      tl.from(children, { y: 40, rotation: 3, opacity: 0, stagger: 0.1, duration: 0.9, ease: "power3.out" });
      break;
    case "stagger-up":
      tl.from(children, { y: 60, opacity: 0, stagger: 0.15, duration: 0.8, ease: "power3.out" });
      break;
    case "clip-reveal":
      tl.from(children, { clipPath: "inset(100% 0 0 0)", opacity: 0, stagger: 0.15, duration: 1.2, ease: "power4.inOut" });
      break;
  }

  let hasPlayed = false;

  ScrollTrigger.create({
    trigger: scrollContainer,
    start: "top top",
    end: "bottom bottom",
    scrub: false,
    onUpdate: (self) => {
      const p = self.progress;
      const inRange = p >= enter && p <= leave;
      const pastRange = p > leave;

      if (inRange && !hasPlayed) {
        tl.play();
        hasPlayed = true;
        section.style.opacity = 1;
        section.style.pointerEvents = "auto";
      } else if (!inRange && hasPlayed && !persist) {
        tl.reverse();
        hasPlayed = false;
      }

      // Fade out when leaving range (unless persist)
      if (pastRange && !persist) {
        section.style.opacity = 0;
        section.style.pointerEvents = "none";
      }
      // Persist sections stay visible and interactive after entering
    }
  });
}

// Initialize all sections
document.querySelectorAll(".scroll-section").forEach(setupSectionAnimation);
```

---

## Counter Animations

Uses the same progress-based system as section animations, since stat sections are `position: absolute` inside the scroll container (viewport-relative triggers won't fire correctly for them):

```js
function setupCounters(scrollContainer) {
  document.querySelectorAll(".stat-number").forEach(el => {
    const section = el.closest(".scroll-section");
    const enter = parseFloat(section.dataset.enter) / 100;
    const leave = parseFloat(section.dataset.leave) / 100;
    const decimals = parseInt(el.dataset.decimals || "0");
    const target = parseFloat(el.dataset.value);
    let hasPlayed = false;

    const tween = gsap.fromTo(el,
      { textContent: 0 },
      { textContent: target, duration: 2, ease: "power1.out",
        snap: { textContent: decimals === 0 ? 1 : 0.01 }, paused: true }
    );

    ScrollTrigger.create({
      trigger: scrollContainer,
      start: "top top",
      end: "bottom bottom",
      scrub: false,
      onUpdate: (self) => {
        const p = self.progress;
        if (p >= enter && p <= leave && !hasPlayed) {
          tween.play();
          hasPlayed = true;
        } else if (p < enter && hasPlayed) {
          tween.reverse();
          hasPlayed = false;
        }
      }
    });
  });
}
```

---

## Horizontal Text Marquee

```js
document.querySelectorAll(".marquee-wrap").forEach(el => {
  const speed = parseFloat(el.dataset.scrollSpeed) || -25;
  const enterAt = parseFloat(el.dataset.enter || "20") / 100;
  const leaveAt = parseFloat(el.dataset.leave || "80") / 100;
  const text = el.querySelector(".marquee-text");

  gsap.to(text, {
    xPercent: speed,
    ease: "none",
    scrollTrigger: { trigger: scrollContainer, start: "top top", end: "bottom bottom", scrub: true }
  });

  // Fade marquee in/out based on its scroll range
  ScrollTrigger.create({
    trigger: scrollContainer,
    start: "top top",
    end: "bottom bottom",
    scrub: true,
    onUpdate: (self) => {
      const p = self.progress;
      const fadeRange = 0.03;
      let opacity = 0;
      if (p >= enterAt && p <= leaveAt) opacity = 1;
      else if (p >= enterAt - fadeRange && p < enterAt) opacity = (p - (enterAt - fadeRange)) / fadeRange;
      else if (p > leaveAt && p <= leaveAt + fadeRange) opacity = 1 - (p - leaveAt) / fadeRange;
      el.style.opacity = opacity;
    }
  });
});
```

---

## Dark Overlay

```js
function initDarkOverlay(enter, leave) {
  const overlay = document.getElementById("dark-overlay");
  const fadeRange = 0.04;
  ScrollTrigger.create({
    trigger: scrollContainer,
    start: "top top",
    end: "bottom bottom",
    scrub: true,
    onUpdate: (self) => {
      const p = self.progress;
      let opacity = 0;
      if (p >= enter - fadeRange && p <= enter) opacity = (p - (enter - fadeRange)) / fadeRange;
      else if (p > enter && p < leave) opacity = 0.9;
      else if (p >= leave && p <= leave + fadeRange) opacity = 0.9 * (1 - (p - leave) / fadeRange);
      overlay.style.opacity = opacity;
    }
  });
}
```

---

## Circle-Wipe Hero Reveal

```js
function initHeroTransition() {
  const heroSection = document.querySelector(".hero-standalone");
  const canvasWrap = document.querySelector(".canvas-wrap");

  ScrollTrigger.create({
    trigger: scrollContainer,
    start: "top top",
    end: "bottom bottom",
    scrub: true,
    onUpdate: (self) => {
      const p = self.progress;
      // Hero fades out as scroll begins
      heroSection.style.opacity = Math.max(0, 1 - p * 15);
      // Canvas reveals via expanding circle clip-path
      const wipeProgress = Math.min(1, Math.max(0, (p - 0.01) / 0.06));
      const radius = wipeProgress * 75;
      canvasWrap.style.clipPath = `circle(${radius}% at 50% 50%)`;
    }
  });
}
```
