---
name: media-write
description: |
  Guided co-creation writing skill. Interviews the user, drafts content
  section by section, generates platform-specific variants from shared
  source. Creates the content manifest. Works with a brief from /media-idea
  or accepts freeform input.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - AskUserQuestion
  - Grep
  - Glob
---

# /media-write — Guided Writing & Variant Generation

Write content collaboratively, then generate platform-specific variants.

## Prerequisites

Before starting, read these shared library files:
- Read `lib/adapter-discovery.md` for adapter format.md location
- Read `lib/manifest-ops.md` for manifest creation

## Step 1: Get the Brief

Check if a brief exists from `/media-idea`:
```bash
ls -t content/posts/*/brief.yaml 2>/dev/null | head -1
```

If a brief exists, read it and show the user:
- Topic, angle, outline, target platforms

If no brief exists, ask the user via AskUserQuestion:
1. "What do you want to write about?"
2. "Who is the audience?" (developers, beginners, specific community)
3. "Which platforms should we target?" (show configured platforms)

## Step 2: Create Post Directory

```bash
SLUG=$(echo "<title>" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')
DATE=$(date +%Y-%m-%d)
POST_DIR="content/posts/${DATE}-${SLUG}"
mkdir -p "$POST_DIR/assets" "$POST_DIR/variants"
```

## Step 3: Guided Section-by-Section Writing

Work through the article section by section:

### Interaction model

1. **Propose an outline** based on the brief/topic. Use AskUserQuestion:
   "Here's my proposed outline for '<title>'. Approve or suggest changes?"
   Show 4-7 sections with one-line descriptions.

2. **For each section:**
   - Propose the section content in chat (2-4 paragraphs)
   - Use AskUserQuestion: "How does this section look?"
     - A) Approve — move to next section
     - B) Shorter / more concise
     - C) More technical / add code examples
     - D) Different angle (provide feedback)
   - On approval, append the section to `source.md` using the Write or Edit tool
   - User can say "go back to section N" to revise earlier sections

3. **The file is the source of truth.** All approved content lives in `source.md`.
   Chat is the collaboration channel for drafting and feedback.

### Writing guidelines

- Write in the user's voice (if brand voice is configured in `content/config/voice.yaml`, read it first)
- Include code examples where relevant for a developer audience
- Use clear headers (## for sections, ### for subsections)
- Keep paragraphs concise (3-5 sentences)
- Add image placeholders where visuals would help: `![description](assets/placeholder.png)`

## Step 4: Finalize Source

Once all sections are approved, read the complete `source.md` back to confirm.

Use AskUserQuestion:
"Here's the complete article. Ready to generate platform variants?"
- A) Yes, generate variants
- B) I want to edit more (specify which section)

## Step 5: Generate Platform Variants

For each configured platform adapter:

1. Read the adapter's `format.md`:
   ```bash
   cat adapters/<name>/format.md
   ```

2. Following the adaptation rules in `format.md`, generate the variant from `source.md`:
   - Apply frontmatter template
   - Adapt content structure (length, tone, format)
   - Convert image paths as needed
   - Add platform-specific elements (canonical URL, tags, etc.)

3. Write the variant to `<post_dir>/variants/<name>.md`

## Step 6: Create Manifest

Create `manifest.yaml` following the format in `lib/manifest-ops.md`:

```yaml
title: "<title>"
created: <ISO 8601 now>
updated: <ISO 8601 now>
source: source.md
tags: [<from brief or article>]
language: en
canonical_url: ""

assets: []

variants:
  <for each adapter>:
    file: variants/<name>.md
    format: <from adapter.yaml content_format>
    status: draft
    error: null
```

Use the atomic write pattern from `lib/manifest-ops.md`.

## Step 7: Summary

```
Article written and variants generated:

  source.md — <word count> words
  variants/devto.md — Dev.to format (draft)
  variants/hashnode.md — Hashnode format (draft)
  variants/github-pages.md — GitHub Pages format (draft)

Next steps:
  - Run /media-image to generate illustrations
  - Run /media-publish to publish to all platforms
  - Or run /media-publish --dry-run to preview first
```

## Updating Existing Content

When invoked with `--update` flag or on a post that already has `source.md`:

1. Read the existing `source.md` and `manifest.yaml`
2. Ask what the user wants to change
3. Edit the relevant sections
4. Regenerate ONLY the variant files (re-read each adapter's `format.md` and re-adapt)
5. Reset variant statuses to `draft` for regenerated variants
6. Do NOT overwrite variants with status `published` unless the user explicitly confirms
