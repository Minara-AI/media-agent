# Image Processing

How to generate, resize, and manage images for posts.

## Dependencies

- ImageMagick (`convert` command) for resizing and cropping
- Check availability: `which convert`
- Install: `brew install imagemagick` (macOS) or `apt install imagemagick` (Linux)

## Image Generation — Configurable Backend

The image provider is configured via `IMAGE_PROVIDER` in `.env`. Supported values:
`openai` (default), `flux`, `ideogram`.

### Detect provider

```bash
IMAGE_PROVIDER=$(grep "^IMAGE_PROVIDER=" .env 2>/dev/null | cut -d= -f2- || echo "openai")
echo "Image provider: $IMAGE_PROVIDER"
```

### Provider: OpenAI (GPT Image)

Best for: general-purpose images, wide API adoption, key reuse if already using OpenAI.
Elo: ~1264. Price: $0.005-0.08/image.

```bash
curl -s https://api.openai.com/v1/images/generations \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-image-1",
    "prompt": "<prompt>",
    "n": 1,
    "size": "1536x1024",
    "quality": "medium"
  }' | python3 -c "
import sys, json, base64
data = json.load(sys.stdin)['data'][0]
if 'url' in data:
    print(data['url'])
elif 'b64_json' in data:
    import pathlib
    pathlib.Path('<output_path>').write_bytes(base64.b64decode(data['b64_json']))
    print('<output_path>')
"
```

### Provider: Flux (via Replicate)

Best for: photorealism, cost-effective batch generation.
Elo: ~1265. Price: $0.015-0.055/image. Speed: 4.5s.

Requires `REPLICATE_API_TOKEN` in `.env`.

```bash
# Start generation
PREDICTION_URL=$(curl -s -X POST "https://api.replicate.com/v1/predictions" \
  -H "Authorization: Bearer $REPLICATE_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "black-forest-labs/flux-2-pro",
    "input": {
      "prompt": "<prompt>",
      "width": 1536,
      "height": 1024
    }
  }' | python3 -c "import sys,json; print(json.load(sys.stdin)['urls']['get'])")

# Poll for result (typically 5-15s)
sleep 5
OUTPUT_URL=$(curl -s -H "Authorization: Bearer $REPLICATE_API_TOKEN" "$PREDICTION_URL" \
  | python3 -c "import sys,json; r=json.load(sys.stdin); print(r['output'][0] if r['status']=='succeeded' else '')")

curl -s -o "<output_path>" "$OUTPUT_URL"
```

### Provider: Ideogram

Best for: images with text/titles on them (90-95% text accuracy). Great for cover images with article title overlay.
Elo: ~1200. Price: ~$0.04/image.

Requires `IDEOGRAM_API_KEY` in `.env`.

```bash
curl -s -X POST "https://api.ideogram.ai/generate" \
  -H "Api-Key: $IDEOGRAM_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "image_request": {
      "prompt": "<prompt>",
      "model": "V_3",
      "magic_prompt_option": "AUTO",
      "aspect_ratio": "ASPECT_3_2"
    }
  }' | python3 -c "import sys,json; print(json.load(sys.stdin)['data'][0]['url'])"
```

### Diagrams (excalidraw-skill)

For architecture diagrams, flowcharts, and concept maps, use `/excalidraw` instead of
the image generation API. See the `/media-image` skill for details.

## Platform image sizes

| Platform | Type | Size | ImageMagick command |
|----------|------|------|-------------------|
| Blog hero | Cover | 1200x630 | `convert hero.png -resize 1200x630^ -gravity center -extent 1200x630 hero-blog.png` |
| Twitter/X | Card | 1200x675 | `convert hero.png -resize 1200x675^ -gravity center -extent 1200x675 hero-twitter.png` |
| Dev.to | Cover | 1000x420 | `convert hero.png -resize 1000x420^ -gravity center -extent 1000x420 hero-devto.png` |
| Hashnode | Cover | 1600x840 | `convert hero.png -resize 1600x840^ -gravity center -extent 1600x840 hero-hashnode.png` |
| WeChat | Header | 900x383 | `convert hero.png -resize 900x383^ -gravity center -extent 900x383 hero-wechat.png` |
| In-article | Illustration | 800x600 | `convert image.png -resize 800x600 image-article.png` |

## Updating manifest with assets

After generating images, add them to the manifest's `assets` list:

```yaml
assets:
  - name: hero.png
    prompt: "<the prompt used>"
    generator: openai  # or flux, ideogram, excalidraw
    generated: <ISO 8601 timestamp>
    sizes:
      blog: assets/hero-blog.png
      devto: assets/hero-devto.png
      hashnode: assets/hero-hashnode.png
```

## Fallback when image generation is unavailable

If no image API key is configured:
1. Report to the user: "No image generation API configured. You can add your own images to the assets/ directory, or configure a provider in .env (IMAGE_PROVIDER=openai|flux|ideogram)."
2. Continue the workflow without images. The publish step will skip image fields.
