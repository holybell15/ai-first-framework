---
name: web-artifacts-builder
description: "Build complex, multi-page web artifacts with React + shadcn/ui. Use this for: 做一個複雜的 HTML 應用, 需要多個頁面的 artifact, React 元件, 有 routing 的, shadcn/ui components. Perfect for anything beyond a simple single-file HTML."
license: Complete terms in LICENSE.txt
---

# Web Artifacts Builder

For powerful, sophisticated frontend artifacts, follow these steps:

1. Initialize the frontend repo using `scripts/init-artifact.sh`
2. Develop your artifact by editing the generated code
3. Bundle all code into a single HTML file using `scripts/bundle-artifact.sh`
4. Display artifact to user

**Stack**: React 18 + TypeScript + Vite + Parcel (bundling) + Tailwind CSS + shadcn/ui

## Design & Style Guidelines

To avoid what's often called "AI slop", avoid:
- Excessive centered layouts
- Purple gradients
- Uniform rounded corners
- Inter font

## Quick Start

### Step 1: Initialize Project

Run the initialization script to create a new React project:
```bash
bash scripts/init-artifact.sh <project-name>
cd <project-name>
```

This creates a fully configured project with:
- React + TypeScript (via Vite)
- Tailwind CSS 3.4.1 with shadcn/ui theming system
- Path aliases (`@/`) configured
- 40+ shadcn/ui components pre-installed
- All Radix UI dependencies included
- Parcel configured for bundling
- Node 18+ compatibility

### Step 2: Develop Your Artifact

Edit the generated files. See **Common Development Tasks** below for guidance.

### Step 3: Bundle to Single HTML File

To bundle the React app into a single HTML artifact:
```bash
bash scripts/bundle-artifact.sh
```

This creates `bundle.html` - a self-contained artifact with all JavaScript, CSS, and dependencies inlined. This file can be directly shared in Claude conversations as an artifact.

**Requirements**: Your project must have an `index.html` in the root directory.

**What the script does**:
- Installs bundling dependencies (parcel, @parcel/config-default, parcel-resolver-tspaths, html-inline)
- Creates `.parcelrc` config with path alias support
- Builds with Parcel (no source maps)
- Inlines all assets into single HTML using html-inline

### Step 4: Share Artifact with User

Display the bundled HTML file in conversation so users can view it as an artifact.

### Step 5: Testing/Visualizing the Artifact (Optional)

Note: This is completely optional. Only perform if necessary or requested.

To test/visualize the artifact, use available tools. In general, avoid testing the artifact upfront as it adds latency. Test later if requested or if issues arise.

---

## When to Use This Skill vs. Simple Artifacts

**Use Web Artifacts Builder for:**
- Multi-page applications with routing
- Complex state management
- Using multiple shadcn/ui components
- Interactive dashboards or tools
- Anything requiring professional-grade architecture

**Use simple artifacts for:**
- Single HTML files with inline CSS/JS
- Quick, one-off visualizations
- Simple forms or displays
- Anything that fits in 1-2 hundred lines

---

## Reference

- **shadcn/ui components**: https://ui.shadcn.com/docs/components
