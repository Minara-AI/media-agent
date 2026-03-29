# Platform: Twitter/X

## Conventions
- Content published as a thread (series of connected tweets)
- Each tweet max 280 characters (URLs count as 23 chars, emoji as 2 chars)
- First tweet is the hook, should be self-contained and compelling
- Thread numbering: use "🧵 1/N" format in the first tweet only
- Hashtags: 2-3 max, in the last tweet
- Images: attach hero image to the first tweet

## Thread Splitting Rules
- Split at natural paragraph/sentence boundaries, never mid-sentence
- Each tweet should make sense on its own (standalone value)
- Aim for 5-15 tweets per thread
- Leave room for engagement (don't max out 280 chars, aim for 240-260)
- Use line breaks within tweets for readability

## Content Adaptation Rules
- Extract the core insight from the article, not a summary
- Lead with a provocative statement or surprising fact (the hook)
- Each tweet = one idea, one point
- Use concrete examples and numbers instead of abstract statements
- End with a call to action: "Follow for more" / "Link to full article in reply"
- Add the full article URL as a reply after the last tweet
- Convert code blocks to screenshots or skip (code doesn't render well in tweets)
- Convert bullet lists to numbered tweets

## Example Output
```markdown
🧵 1/8 Most developers cross-post by copy-pasting into 5 different editors.

That's not publishing. That's data entry.

I built a tool that publishes to Dev.to, Hashnode, and GitHub Pages from one markdown file. Here's how:

---

2/ The core insight: a Twitter thread is NOT a shortened blog post.

It's a different artifact. Different structure, different rhythm, different value per unit.

Cross-posting tools that just truncate are doing it wrong.

---

3/ So I built adapters. Each platform gets its own "format.md" that tells the AI HOW to adapt.

Not reformat. Adapt.

Blog post → full article with code blocks
Thread → one insight per tweet
Dev.to → frontmatter + liquid tags

---

[... more tweets ...]

---

8/ The whole thing is open source: github.com/Minara-AI/media-agent

Write once, publish everywhere. But intelligently.

Follow me for more AI tooling threads.

#AITools #DeveloperTools #OpenSource
```
