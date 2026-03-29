# Platform: 微信公众号 (WeChat Official Account)

## Conventions
- Articles are HTML, not markdown (WeChat renders HTML in its reader)
- Title max 64 characters
- Single article per publish (not multi-article push)
- Images must be uploaded to WeChat's material library first (get media_id)
- Code blocks: use `<pre><code>` tags with inline styling
- No external image URLs allowed, all images must be WeChat-hosted

## Content Adaptation Rules
- Convert markdown to clean HTML
- Inline all styles (WeChat strips `<style>` tags and external CSS)
- Use `<section>` tags for major sections
- Headings: `<h2>` for sections, `<h3>` for subsections (no `<h1>`)
- Images: must use `wx:` protocol media URLs (uploaded via material API)
- Code blocks: wrap in `<pre style="background:#f6f8fa;padding:16px;border-radius:6px;overflow-x:auto;font-size:14px;"><code>...</code></pre>`
- Links: WeChat only allows links to other WeChat articles or whitelisted domains
- Paragraphs: use `<p style="margin-bottom:16px;line-height:1.8;">` for readability
- Add a brief intro paragraph that appears in the article list preview (digest)
- End with a call to action: "关注公众号获取更多技术文章"

## HTML Template
```html
<section style="padding:0 8px;">
  <p style="margin-bottom:16px;line-height:1.8;">
    {intro paragraph}
  </p>

  <h2 style="font-size:20px;font-weight:bold;margin:24px 0 12px;">
    {section title}
  </h2>

  <p style="margin-bottom:16px;line-height:1.8;">
    {content}
  </p>

  <img src="{wx_media_url}" style="width:100%;border-radius:4px;margin:12px 0;" />

  <pre style="background:#f6f8fa;padding:16px;border-radius:6px;overflow-x:auto;font-size:14px;line-height:1.5;">
    <code>{code}</code>
  </pre>
</section>
```

## Metadata (passed via API)
- title: string (max 64 chars)
- author: string
- digest: string (preview text, max 120 chars)
- thumb_media_id: string (cover image, uploaded via material API)
- content: string (full HTML body)
- content_source_url: string (original article URL, "阅读原文" link)

## Example Output
```html
<section style="padding:0 8px;">
  <p style="margin-bottom:16px;line-height:1.8;">
    AI Agent 正在改变我们构建软件的方式。在本教程中，我将带你使用 Claude Code Skills 构建你的第一个 Agent。
  </p>

  <h2 style="font-size:20px;font-weight:bold;margin:24px 0 12px;">
    为什么 AI Agent 很重要
  </h2>

  <p style="margin-bottom:16px;line-height:1.8;">
    内容...
  </p>

  <p style="margin-bottom:16px;line-height:1.8;color:#888;font-size:14px;">
    — 关注公众号获取更多技术文章
  </p>
</section>
```
