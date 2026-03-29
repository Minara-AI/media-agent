---
name: media-image
description: |
  Generate and manage images for posts. Uses excalidraw-skill for diagrams
  and illustrations (hand-drawn style). Optionally uses DALL-E for
  photo-style hero images. Handles platform-specific resizing with
  ImageMagick. Updates the content manifest with asset references.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - AskUserQuestion
  - Grep
  - Glob
---

# /media-image — Image Generation & Management

Generate contextual images for your post and resize them for each platform.

Uses [excalidraw-skill](https://github.com/Minara-AI/excalidraw-skill) for diagrams
and illustrations (hand-drawn Excalidraw style). Optionally uses DALL-E for
photo-style hero images.

## Prerequisites

Before starting, read these shared library files:
- Read `lib/image-processing.md` for resizing commands and platform sizes
- Read `lib/manifest-ops.md` for updating the manifest
- Read `lib/adapter-discovery.md` for platform image size requirements

## Step 1: Locate the Post

If the user specifies a post path, use it. Otherwise, find the most recent post:
```bash
ls -dt content/posts/*/ 2>/dev/null | head -1
```

Read `source.md` to understand the content. Read `manifest.yaml` for existing state.

## Step 2: Check Dependencies

```bash
echo "=== Image Dependencies ==="

# Check ImageMagick (for resizing)
which convert >/dev/null 2>&1 && echo "[OK] ImageMagick" || echo "[MISSING] ImageMagick — needed for resizing (brew install imagemagick)"

# Check excalidraw-skill (for diagrams)
EXCALIDRAW_SKILL=""
[ -f ".claude/skills/excalidraw-skill/skill/SKILL.md" ] && EXCALIDRAW_SKILL="local"
[ -f "$HOME/.claude/skills/excalidraw-skill/skill/SKILL.md" ] && EXCALIDRAW_SKILL="global"
[ -n "$EXCALIDRAW_SKILL" ] && echo "[OK] excalidraw-skill ($EXCALIDRAW_SKILL)" || echo "[MISSING] excalidraw-skill — install from https://github.com/Minara-AI/excalidraw-skill"

# Check OpenAI API key (optional, for photo-style hero images)
grep -q "^OPENAI_API_KEY=." .env 2>/dev/null && echo "[OK] DALL-E (photo hero images)" || echo "[OPTIONAL] No OPENAI_API_KEY — DALL-E unavailable, using excalidraw only"
```

## Step 3: Plan Images

Analyze `source.md` and identify where images would add value:

1. **Hero/cover image:** A cover image that captures the article's theme
2. **In-article diagrams:** Architecture diagrams, flowcharts, concept maps
3. **In-article illustrations:** Visual explanations for complex concepts

Use AskUserQuestion to present the image plan:
"Here are the images I'd generate for this post. Approve or modify?"

For each image, show:
- Description of what it depicts
- Where it appears in the article
- Generation method: `/excalidraw` (diagram) or DALL-E (photo-style)

Options:
- A) Generate all
- B) Select specific images
- C) I'll provide my own images (skip to Step 6)
- D) Skip images entirely

## Step 4: Generate Images

### Diagrams and illustrations (excalidraw-skill)

For each diagram/illustration, use the `/excalidraw` skill:

```
/excalidraw Draw <description> — output to <post_dir>/assets/<filename>.png
```

The excalidraw-skill generates hand-drawn style diagrams with Virgil font,
hachure fills, and clean monochrome aesthetics. It's ideal for:
- Architecture diagrams
- Flowcharts and workflows
- Concept maps
- System component diagrams
- Before/after comparisons

If excalidraw-skill is not installed, tell the user:
"excalidraw-skill not found. Install it for diagram generation:
`bash /path/to/excalidraw-skill/install.sh`
Or provide your own images in the assets/ directory."

### Photo-style hero images (DALL-E, optional)

If the user wants a photo-style hero image AND `OPENAI_API_KEY` is configured:

```bash
source .env
URL=$(curl -s https://api.openai.com/v1/images/generations \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"dall-e-3\",\"prompt\":\"<prompt>\",\"n\":1,\"size\":\"1792x1024\",\"quality\":\"standard\"}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['data'][0]['url'])")

curl -s -o "<post_dir>/assets/hero.png" "$URL"
```

If DALL-E is unavailable, use excalidraw for the hero image too, or skip it.

## Step 5: Resize for Platforms

For each configured adapter, read `adapter.yaml` to get image sizes. Resize using ImageMagick:

```bash
# Example for Dev.to cover (1000x420)
convert "<post_dir>/assets/hero.png" \
  -resize 1000x420^ -gravity center -extent 1000x420 \
  "<post_dir>/assets/hero-devto.png"
```

Generate all platform-specific sizes as listed in `lib/image-processing.md`.

If ImageMagick is not installed, warn the user and skip resizing. The original
images will be used (platforms may crop them differently).

## Step 6: Update Manifest

Add generated images to the manifest's `assets` list:

```yaml
assets:
  - name: hero.png
    type: photo
    prompt: "<prompt used>"
    generator: dall-e-3
    generated: <ISO 8601 timestamp>
    sizes:
      devto: assets/hero-devto.png
      hashnode: assets/hero-hashnode.png
      github-pages: assets/hero-blog.png
  - name: architecture-diagram.png
    type: diagram
    prompt: "<description>"
    generator: excalidraw
    generated: <ISO 8601 timestamp>
```

Use the atomic write pattern from `lib/manifest-ops.md`.

## Step 7: Update Variant Image References

For each variant file in `variants/`, update image paths to reference the
platform-specific resized version. For example, in `variants/devto.md`,
change cover_image to point to `hero-devto.png`.

## Step 8: Summary

```
Images generated for "<title>":

  [OK] hero.png — cover image via DALL-E (1792x1024)
       → hero-devto.png (1000x420)
       → hero-hashnode.png (1600x840)
       → hero-blog.png (1200x630)
  [OK] architecture-diagram.png — via excalidraw-skill
  [OK] workflow.png — via excalidraw-skill

Manifest updated. Next: run /media-publish to publish.
```
