---
name: media-idea
description: |
  Brainstorming and ideation skill. Interviews the user about topics,
  audience, and angle. Suggests titles, outlines, and hooks. Optionally
  researches trending topics. Outputs a structured brief for /media-write.
allowed-tools:
  - Bash
  - Read
  - Write
  - AskUserQuestion
  - WebSearch
  - Grep
  - Glob
---

# /media-idea — Brainstorming & Ideation

Brainstorm your next piece of content and produce a structured brief.

## Step 1: Understand the User's Direction

Use AskUserQuestion to explore:

**Question 1:** "What topic or area are you thinking about? It can be vague — we'll sharpen it together."

**Question 2:** "Who's the audience?"
- A) Developers (general)
- B) Beginners learning to code
- C) Senior engineers / architects
- D) Specific community (describe)

**Question 3:** "What's the goal of this piece?"
- A) Teach something (tutorial, how-to)
- B) Share an opinion or insight
- C) Announce something (project, release)
- D) Tell a story (case study, post-mortem)

## Step 2: Research (Optional)

If the user's topic would benefit from current context, offer to search:

"Want me to look up what's being discussed about this topic right now? I can search for recent articles and discussions to help find a unique angle."

If yes, use WebSearch with 2-3 queries:
- "<topic> blog post 2026"
- "<topic> developer tutorial"
- "<topic> common mistakes"

Summarize findings: what angles are already covered, where there's a gap.

## Step 3: Generate Ideas

Based on the user's input and research, propose 3-5 content ideas. For each:
- **Title** (compelling, specific)
- **Angle** (what makes this different from existing content)
- **Format** (tutorial, opinion piece, case study, listicle)
- **Estimated length** (short: 500-1000 words, medium: 1000-2000, long: 2000+)

Use AskUserQuestion: "Which of these speaks to you? Or describe something different."

## Step 4: Develop the Chosen Idea

For the selected idea, propose a detailed outline:

- **Hook** (opening sentence/paragraph that grabs attention)
- **Sections** (4-7 sections with one-line descriptions)
- **Key takeaway** (what the reader leaves with)
- **Call to action** (what the reader should do next)

Use AskUserQuestion: "How does this outline look?"
- A) Looks good, save the brief
- B) Adjust the outline (describe changes)
- C) Start over with a different idea

## Step 5: Select Target Platforms

Check which adapters are configured:
```bash
for adapter in adapters/*/; do
  name=$(basename "$adapter")
  display=$(python3 -c "import yaml; print(yaml.safe_load(open('${adapter}adapter.yaml'))['display_name'])" 2>/dev/null)
  echo "$name: $display"
done
```

Use AskUserQuestion: "Which platforms should we publish to?"
Show configured platforms with multi-select.

## Step 6: Save the Brief

Create the post directory and save the brief:

```bash
SLUG=$(echo "<title>" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')
DATE=$(date +%Y-%m-%d)
POST_DIR="content/posts/${DATE}-${SLUG}"
mkdir -p "$POST_DIR/assets" "$POST_DIR/variants"
```

Write `brief.yaml`:
```yaml
title: "<title>"
angle: "<angle>"
format: "<tutorial|opinion|case-study|listicle>"
audience: "<audience description>"
goal: "<teach|share|announce|story>"
length: "<short|medium|long>"
platforms: [<selected platforms>]

outline:
  hook: "<opening hook>"
  sections:
    - title: "<section 1>"
      description: "<one-line description>"
    - title: "<section 2>"
      description: "<one-line description>"
  takeaway: "<key takeaway>"
  cta: "<call to action>"

created: <ISO 8601 timestamp>
```

## Step 7: Summary

```
Brief saved for "<title>":

  Post directory: content/posts/<date>-<slug>/
  Format: <format>
  Target platforms: <platforms>
  Sections: <count>

Next: run /media-write to start writing, or /media for the full workflow.
```
