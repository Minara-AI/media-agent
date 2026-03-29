---
name: media
description: |
  Master orchestrator for the media-agent workflow. Guides the user through
  the full content creation pipeline: ideation, writing, image generation,
  and multi-platform publishing. Can resume from any stage by reading the
  content manifest. This is a thin sequencer — sub-skills contain the
  canonical implementation logic.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - AskUserQuestion
  - WebSearch
  - Grep
  - Glob
---

# /media — Full Content Creation Workflow

The complete guided workflow: idea → write → image → publish.

This orchestrator is a thin sequencer. For each stage, it reads the shared
library files and follows the same logic as the individual sub-skills.

## Prerequisites

Read these shared library files before proceeding:
- Read `lib/adapter-discovery.md`
- Read `lib/manifest-ops.md`
- Read `lib/image-processing.md`

## Step 0: Detect State & Resume

Check if there's an in-progress post:

```bash
# Find posts with draft variants (not yet fully published)
for dir in content/posts/*/; do
  if [ -f "$dir/manifest.yaml" ]; then
    has_draft=$(python3 -c "
import yaml
with open('${dir}manifest.yaml') as f:
    m = yaml.safe_load(f)
variants = m.get('variants', {})
drafts = [k for k,v in variants.items() if v.get('status') in ('draft','pending','failed')]
print('yes' if drafts else 'no')
" 2>/dev/null)
    if [ "$has_draft" = "yes" ]; then
      echo "IN_PROGRESS: $dir"
    fi
  fi
done
```

If an in-progress post is found, use AskUserQuestion:
"Found an in-progress post: '<title>'. What would you like to do?"
- A) Resume this post (continue from where we left off)
- B) Start a new post
- C) Finish publishing this post (jump to /media-publish)

### Detecting resume stage

Read the manifest to determine which stage to resume from:
- No `source.md` → resume from ideation/writing (Stage 1-2)
- `source.md` exists but no variants → resume from variant generation (Stage 2, Step 5)
- Variants exist but no assets → resume from image generation (Stage 3)
- Assets exist but variants are `draft` → resume from publishing (Stage 4)

## Stage 1: Ideation

Read `skills/media-idea/SKILL.md` and follow its workflow.

This stage produces a `brief.yaml` in the post directory.

If a `brief.yaml` already exists (resume scenario), skip to Stage 2.

## Stage 2: Writing

Read `skills/media-write/SKILL.md` and follow its workflow.

This stage produces:
- `source.md` (canonical content)
- `variants/<name>.md` for each platform
- `manifest.yaml`

If `source.md` and variants already exist (resume scenario), ask if the user wants
to edit or proceed to images.

## Stage 3: Image Generation

Read `skills/media-image/SKILL.md` and follow its workflow.

This stage produces:
- Images in `assets/`
- Platform-resized versions
- Updated manifest with asset references

If images already exist (resume scenario), ask if the user wants to regenerate or
proceed to publishing.

**Skip condition:** If the user doesn't have an OpenAI API key configured and
doesn't want to provide their own images, skip this stage entirely.

## Stage 4: Publishing

Read `skills/media-publish/SKILL.md` and follow its workflow.

This stage:
- Validates all files
- Publishes to each configured platform
- Updates manifest with URLs and status

## Stage 5: Complete

After publishing, show the final summary:

```
=== Content Published! ===

"<title>"

  Source: content/posts/<slug>/source.md (<word count> words)

  Published to:
    [OK] Dev.to → <url>
    [OK] Hashnode → <url>
    [OK] GitHub Pages → <url>

  Images: <count> generated, resized for <count> platforms

  Manifest: content/posts/<slug>/manifest.yaml

What's next?
  - Run /media to write another post
  - Edit source.md and run /media-write --update to regenerate variants
  - Run /media-publish to retry any failed platforms
```

## Error Handling

If any stage fails:
1. Report the error clearly
2. Save all progress to disk (manifest, source, variants)
3. Offer to retry the failed step or skip to the next stage
4. The user can always resume later — the manifest tracks all state
