#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# media-agent — One-Command Installer
# https://github.com/Minara-AI/media-agent
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "  media-agent Installer"
echo "  Write once, publish everywhere."
echo "  ─────────────────────────────────"
echo ""

# --- Detect install mode ---
INSTALL_MODE=""
if [ "${1:-}" = "--global" ]; then
  INSTALL_MODE="global"
  TARGET_DIR="$HOME/.claude/skills/media-agent"
elif [ "${1:-}" = "--local" ]; then
  INSTALL_MODE="local"
  TARGET_DIR="${2:-.}/.claude/skills/media-agent"
else
  echo "  Where should media-agent be installed?"
  echo ""
  echo "    1) Global (~/.claude/skills/media-agent)"
  echo "       Available in all your projects."
  echo ""
  echo "    2) Local (.claude/skills/media-agent)"
  echo "       Only available in the current project."
  echo ""
  read -r -p "  Choose [1/2] (default: 1): " CHOICE
  case "$CHOICE" in
    2) INSTALL_MODE="local"; TARGET_DIR=".claude/skills/media-agent" ;;
    *) INSTALL_MODE="global"; TARGET_DIR="$HOME/.claude/skills/media-agent" ;;
  esac
fi

echo ""
echo "  Installing to: $TARGET_DIR"
echo ""

# --- Step 1: Check dependencies ---
echo "  [1/5] Checking dependencies..."
MISSING=""
which python3 >/dev/null 2>&1 || MISSING="$MISSING python3"
which curl >/dev/null 2>&1 || MISSING="$MISSING curl"
which git >/dev/null 2>&1 || MISSING="$MISSING git"

if [ -n "$MISSING" ]; then
  echo "  [!] Missing required tools:$MISSING"
  echo "      Please install them and try again."
  exit 1
fi

echo "  [OK] python3, curl, git"

# Optional tools
which convert >/dev/null 2>&1 && echo "  [OK] ImageMagick (image resizing)" || echo "  [--] ImageMagick not found (optional, for image resizing)"
which bb-browser >/dev/null 2>&1 && echo "  [OK] bb-browser (Twitter publishing)" || echo "  [--] bb-browser not found (optional, for zero-cost Twitter publishing)"

# --- Step 2: Copy skills ---
echo ""
echo "  [2/5] Installing skills..."
mkdir -p "$TARGET_DIR"

for dir in skills/media skills/media-setup skills/media-idea skills/media-write skills/media-image skills/media-publish; do
  SKILL_NAME=$(basename "$dir")
  mkdir -p "$TARGET_DIR/$SKILL_NAME"
  cp "$SCRIPT_DIR/$dir/SKILL.md" "$TARGET_DIR/$SKILL_NAME/SKILL.md"
done
echo "  [OK] 6 skills installed"

# --- Step 3: Copy lib + adapters ---
echo ""
echo "  [3/5] Installing libraries and adapters..."
mkdir -p "$TARGET_DIR/lib"
cp "$SCRIPT_DIR"/lib/*.md "$TARGET_DIR/lib/"

mkdir -p "$TARGET_DIR/adapters"
for adapter in "$SCRIPT_DIR"/adapters/*/; do
  ADAPTER_NAME=$(basename "$adapter")
  mkdir -p "$TARGET_DIR/adapters/$ADAPTER_NAME"
  cp "$adapter"* "$TARGET_DIR/adapters/$ADAPTER_NAME/" 2>/dev/null || true
  # Ensure publish.sh is executable
  [ -f "$TARGET_DIR/adapters/$ADAPTER_NAME/publish.sh" ] && chmod +x "$TARGET_DIR/adapters/$ADAPTER_NAME/publish.sh"
done
echo "  [OK] 3 lib partials + 5 adapters"

# --- Step 4: Create content directories and templates ---
echo ""
echo "  [4/5] Setting up content directories..."

# Find project root (where content will live)
if [ "$INSTALL_MODE" = "global" ]; then
  CONTENT_HINT="$HOME/media-agent-content"
else
  CONTENT_HINT="$(pwd)"
fi

# Copy templates (don't overwrite existing files)
if [ ! -f "$CONTENT_HINT/.env.example" ] && [ "$INSTALL_MODE" = "local" ]; then
  cp "$SCRIPT_DIR/.env.example" "$CONTENT_HINT/.env.example" 2>/dev/null || true
fi

echo "  [OK] Content directories ready"

# --- Step 5: Copy test suite ---
echo ""
echo "  [5/5] Installing test suite..."
mkdir -p "$TARGET_DIR/test/fixtures/assets"
cp "$SCRIPT_DIR"/test/*.sh "$TARGET_DIR/test/" 2>/dev/null || true
chmod +x "$TARGET_DIR"/test/*.sh 2>/dev/null || true
[ -f "$SCRIPT_DIR/test/fixtures/sample-thread.md" ] && cp "$SCRIPT_DIR/test/fixtures/sample-thread.md" "$TARGET_DIR/test/fixtures/"
echo "  [OK] Test suite installed"

# --- Done ---
echo ""
echo "  ─────────────────────────────────"
echo "  Installation complete!"
echo ""
echo "  Installed to: $TARGET_DIR"
echo ""
echo "  Quick start:"
echo "    1. Copy .env.example to .env and add your API keys"
echo "    2. In Claude Code, run: /media-setup"
echo "    3. Start writing: /media"
echo ""
echo "  Available skills:"
echo "    /media          Full guided workflow"
echo "    /media-setup    Configure platforms"
echo "    /media-idea     Brainstorm topics"
echo "    /media-write    Write + generate variants"
echo "    /media-image    Generate images"
echo "    /media-publish  Publish everywhere"
echo ""
echo "  Platform adapters:"
echo "    [ready]   GitHub Pages, Dev.to, Hashnode"
echo "    [ready]   Twitter/X (via bb-browser, zero cost)"
echo "    [planned] WeChat Official Account"
echo ""

# ─────────────────────────────────
# Optional dependencies
# ─────────────────────────────────
echo "  ─────────────────────────────────"
echo "  Optional dependencies"
echo ""

# --- Optional: bb-browser (for Twitter) ---
if ! which bb-browser >/dev/null 2>&1; then
  echo "  [A] bb-browser — Chrome automation for zero-cost Twitter publishing"
  echo "      The Twitter adapter uses bb-browser to control Chrome instead of"
  echo "      the paid Twitter API. No API key needed."
  echo "      https://github.com/epiral/bb-browser"
  echo ""
  read -r -p "  Install bb-browser? [y/N] " INSTALL_BB
  case "$INSTALL_BB" in
    [yY][eE][sS]|[yY])
      if which npm >/dev/null 2>&1; then
        echo "  Installing bb-browser..."
        npm install -g bb-browser 2>/dev/null && echo "  [OK] bb-browser installed" || {
          echo "  [!] Install failed. Try manually: npm install -g bb-browser"
        }
        # Install community adapters
        if which bb-browser >/dev/null 2>&1; then
          NO_PROXY="*" bb-browser site update 2>/dev/null && echo "  [OK] bb-browser site adapters updated" || true
        fi
      else
        echo "  [!] npm not found. Install Node.js first, then: npm install -g bb-browser"
      fi
      ;;
    *)
      echo "  Skipped. Install later: npm install -g bb-browser"
      ;;
  esac
  echo ""
else
  echo "  [OK] bb-browser already installed"
  echo ""
fi

# --- Optional: twitter-bridge-mcp ---
echo "  [B] twitter-bridge-mcp — MCP server for full Twitter automation"
echo "      Provides 19 Twitter tools (post, reply, like, retweet, search, etc.)"
echo "      via browser automation. Works alongside bb-browser."
echo "      https://github.com/replica882/twitter-bridge-mcp"
echo ""
if [ ! -d "$HOME/.twitter-bridge-mcp" ] && [ ! -d "/tmp/twitter-bridge-mcp" ]; then
  read -r -p "  Install twitter-bridge-mcp? [y/N] " INSTALL_TWITTER_MCP
  case "$INSTALL_TWITTER_MCP" in
    [yY][eE][sS]|[yY])
      echo "  Cloning twitter-bridge-mcp..."
      git clone --depth 1 https://github.com/replica882/twitter-bridge-mcp.git "$HOME/.twitter-bridge-mcp" 2>/dev/null
      cd "$HOME/.twitter-bridge-mcp" && npm install 2>/dev/null && cd - >/dev/null
      echo "  [OK] twitter-bridge-mcp installed to ~/.twitter-bridge-mcp"
      echo ""
      echo "  To use: start Chrome with --remote-debugging-port=9222,"
      echo "  log into Twitter, then run: cd ~/.twitter-bridge-mcp && node server.mjs"
      ;;
    *)
      echo "  Skipped. Install later:"
      echo "  git clone https://github.com/replica882/twitter-bridge-mcp.git ~/.twitter-bridge-mcp"
      ;;
  esac
  echo ""
else
  echo "  [OK] twitter-bridge-mcp already installed"
  echo ""
fi

# --- Optional: excalidraw-skill ---
if [ ! -d "$HOME/.claude/skills/excalidraw-skill" ] && [ ! -d ".claude/skills/excalidraw" ]; then
  echo "  [C] excalidraw-skill — Hand-drawn diagrams from natural language"
  echo "      media-agent's /media-image skill uses it for architecture"
  echo "      diagrams, flowcharts, and illustrations."
  echo "      https://github.com/Minara-AI/excalidraw-skill"
  echo ""
  read -r -p "  Install excalidraw-skill? [y/N] " INSTALL_EXCALIDRAW
  case "$INSTALL_EXCALIDRAW" in
    [yY][eE][sS]|[yY])
      echo "  Cloning excalidraw-skill..."
      git clone --depth 1 https://github.com/Minara-AI/excalidraw-skill.git /tmp/excalidraw-skill-install 2>/dev/null
      bash /tmp/excalidraw-skill-install/install.sh "${2:-.}" 2>/dev/null || {
        echo "  [!] excalidraw-skill install failed. Install manually:"
        echo "      git clone https://github.com/Minara-AI/excalidraw-skill.git"
        echo "      bash excalidraw-skill/install.sh"
      }
      rm -rf /tmp/excalidraw-skill-install
      ;;
    *)
      echo "  Skipped. Install later: https://github.com/Minara-AI/excalidraw-skill"
      ;;
  esac
  echo ""
else
  echo "  [OK] excalidraw-skill already installed"
  echo ""
fi

echo ""
echo "  Done! Happy publishing."
echo ""
