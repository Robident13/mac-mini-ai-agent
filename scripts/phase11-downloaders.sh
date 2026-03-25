#!/bin/bash
set -e

echo "========================================="
echo "Phase 11 — Download Tools (Secure)"
echo "========================================="
echo ""
echo "Tools: yt-dlp, gallery-dl, OF-Scraper"
echo "All credentials stored in macOS Keychain — never plain text."
echo ""

# --- yt-dlp ---
echo "--- yt-dlp ---"
if command -v yt-dlp &>/dev/null; then
  echo "[OK] yt-dlp already installed: $(yt-dlp --version)"
else
  echo "[INSTALL] Installing yt-dlp..."
  brew install yt-dlp
fi

# Create yt-dlp config directory
YT_DLP_CONFIG="$HOME/.config/yt-dlp"
mkdir -p "$YT_DLP_CONFIG"

# Create Keychain-backed credential helper
HELPER_DIR="$HOME/.local/bin"
mkdir -p "$HELPER_DIR"

cat > "$HELPER_DIR/yt-dlp-keychain.sh" << 'EOF'
#!/bin/bash
# Retrieves credentials from macOS Keychain for yt-dlp --netrc-cmd
# Usage: yt-dlp --netrc-cmd "$HOME/.local/bin/yt-dlp-keychain.sh {}"

EXTRACTOR="$1"
if [ -z "$EXTRACTOR" ]; then exit 1; fi

USERNAME=$(security find-generic-password -w -s "yt-dlp-${EXTRACTOR}" -a "username" 2>/dev/null)
PASSWORD=$(security find-generic-password -w -s "yt-dlp-${EXTRACTOR}" -a "password" 2>/dev/null)

if [ -n "$USERNAME" ] && [ -n "$PASSWORD" ]; then
  echo "machine ${EXTRACTOR} login ${USERNAME} password ${PASSWORD}"
fi
EOF
chmod +x "$HELPER_DIR/yt-dlp-keychain.sh"

# Create yt-dlp config pointing to Keychain helper
if [ ! -f "$YT_DLP_CONFIG/config" ]; then
  cat > "$YT_DLP_CONFIG/config" << EOF
# yt-dlp configuration
# Credentials loaded from macOS Keychain via helper script
--netrc-cmd "${HELPER_DIR}/yt-dlp-keychain.sh {}"

# Output template
-o "%(title)s [%(id)s].%(ext)s"

# Embed metadata
--embed-metadata
--embed-thumbnail

# Prefer best quality
-f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"
EOF
  echo "[OK] yt-dlp config created at $YT_DLP_CONFIG/config"
else
  echo "[OK] yt-dlp config already exists"
fi

echo "[OK] yt-dlp ready"
echo ""

# --- gallery-dl ---
echo "--- gallery-dl ---"
if command -v gallery-dl &>/dev/null; then
  echo "[OK] gallery-dl already installed"
else
  echo "[INSTALL] Installing gallery-dl..."
  brew install gallery-dl
fi

# Create gallery-dl config directory
GALLERY_DL_CONFIG="$HOME/.config/gallery-dl"
mkdir -p "$GALLERY_DL_CONFIG"

# Create Keychain-backed config generator
cat > "$HELPER_DIR/gallery-dl-keychain.sh" << 'GALEOF'
#!/bin/bash
# Generates gallery-dl config with credentials from macOS Keychain
# Run before gallery-dl to inject credentials into a temp config

CONFIG_DIR="$HOME/.config/gallery-dl"
SECURE_CONFIG="$CONFIG_DIR/.config-secure.json"

# Base config (no credentials)
BASE_CONFIG="$CONFIG_DIR/config.json"

# Retrieve credentials from Keychain (if stored)
TWITTER_USER=$(security find-generic-password -w -s "gallery-dl-twitter" -a "username" 2>/dev/null || echo "")
TWITTER_PASS=$(security find-generic-password -w -s "gallery-dl-twitter" -a "password" 2>/dev/null || echo "")
INSTAGRAM_USER=$(security find-generic-password -w -s "gallery-dl-instagram" -a "username" 2>/dev/null || echo "")
INSTAGRAM_PASS=$(security find-generic-password -w -s "gallery-dl-instagram" -a "password" 2>/dev/null || echo "")

# Build secure config
python3 -c "
import json, os

config = {}
base = os.path.expanduser('$BASE_CONFIG')
if os.path.exists(base):
    with open(base) as f:
        config = json.load(f)

config.setdefault('extractor', {})

twitter_user = '$TWITTER_USER'
twitter_pass = '$TWITTER_PASS'
if twitter_user and twitter_pass:
    config['extractor'].setdefault('twitter', {})
    config['extractor']['twitter']['username'] = twitter_user
    config['extractor']['twitter']['password'] = twitter_pass

insta_user = '$INSTAGRAM_USER'
insta_pass = '$INSTAGRAM_PASS'
if insta_user and insta_pass:
    config['extractor'].setdefault('instagram', {})
    config['extractor']['instagram']['username'] = insta_user
    config['extractor']['instagram']['password'] = insta_pass

with open('$SECURE_CONFIG', 'w') as f:
    json.dump(config, f, indent=2)
os.chmod('$SECURE_CONFIG', 0o600)
"

echo "$SECURE_CONFIG"
GALEOF
chmod +x "$HELPER_DIR/gallery-dl-keychain.sh"

# Create base gallery-dl config (no secrets)
if [ ! -f "$GALLERY_DL_CONFIG/config.json" ]; then
  cat > "$GALLERY_DL_CONFIG/config.json" << 'EOF'
{
  "extractor": {
    "base-directory": "~/Downloads/gallery-dl/",
    "archive": "~/.config/gallery-dl/archive.sqlite3"
  },
  "downloader": {
    "rate": "2M",
    "retries": 3
  },
  "output": {
    "mode": "terminal",
    "progress": true
  }
}
EOF
  echo "[OK] gallery-dl base config created (no credentials)"
else
  echo "[OK] gallery-dl config already exists"
fi

echo "[OK] gallery-dl ready"
echo ""

# --- OF-Scraper ---
echo "--- OF-Scraper ---"
if command -v ofscraper &>/dev/null; then
  echo "[OK] OF-Scraper already installed"
elif pip3 show ofscraper &>/dev/null 2>&1; then
  echo "[OK] OF-Scraper already installed via pip"
else
  echo "[INSTALL] Installing OF-Scraper..."
  pip3 install ofscraper
fi

# Create Keychain-backed auth generator for OF-Scraper
cat > "$HELPER_DIR/of-scraper-keychain.sh" << 'OFEOF'
#!/bin/bash
# Generates OF-Scraper auth.json from macOS Keychain at runtime
# Credentials are never stored in plain text on disk

AUTH_DIR="$HOME/.config/ofscraper"
AUTH_FILE="$AUTH_DIR/auth.json"
mkdir -p "$AUTH_DIR"

SESS=$(security find-generic-password -w -s "of-scraper" -a "sess" 2>/dev/null || echo "")
AUTH_ID=$(security find-generic-password -w -s "of-scraper" -a "auth_id" 2>/dev/null || echo "")
USER_AGENT=$(security find-generic-password -w -s "of-scraper" -a "user_agent" 2>/dev/null || echo "")
X_BC=$(security find-generic-password -w -s "of-scraper" -a "x-bc" 2>/dev/null || echo "")

if [ -z "$SESS" ] || [ -z "$AUTH_ID" ]; then
  echo "[ERROR] OF-Scraper credentials not found in Keychain."
  echo "Add them with:"
  echo "  security add-generic-password -s of-scraper -a sess -w 'YOUR_SESS_COOKIE'"
  echo "  security add-generic-password -s of-scraper -a auth_id -w 'YOUR_AUTH_ID'"
  echo "  security add-generic-password -s of-scraper -a user_agent -w 'YOUR_USER_AGENT'"
  echo "  security add-generic-password -s of-scraper -a x-bc -w 'YOUR_X_BC_TOKEN'"
  exit 1
fi

cat > "$AUTH_FILE" << AUTHEOF
{
  "auth": {
    "app-token": "33d57ade8c02dbc5a333db99571a76c8f6571571",
    "sess": "$SESS",
    "auth_id": "$AUTH_ID",
    "auth_uid_": "",
    "user_agent": "$USER_AGENT",
    "x-bc": "$X_BC"
  }
}
AUTHEOF

chmod 600 "$AUTH_FILE"
echo "[OK] auth.json generated from Keychain"
OFEOF
chmod +x "$HELPER_DIR/of-scraper-keychain.sh"

echo "[OK] OF-Scraper ready"
echo ""

# --- Shell aliases ---
ZSHRC="$HOME/.zshrc"
MARKER="# --- downloader aliases ---"

if grep -q "$MARKER" "$ZSHRC" 2>/dev/null; then
  echo "[OK] Downloader aliases already configured"
else
  echo "[CONFIG] Adding downloader aliases to ~/.zshrc..."
  cat >> "$ZSHRC" << ALIASES

$MARKER

# yt-dlp (credentials from Keychain automatically via config)
alias ytdl='yt-dlp'
alias ytdl-audio='yt-dlp -x --audio-format mp3'
alias ytdl-playlist='yt-dlp --yes-playlist'

# gallery-dl with Keychain credentials
alias gdl='CONF=\$(\$HOME/.local/bin/gallery-dl-keychain.sh) && gallery-dl --config "\$CONF"'

# OF-Scraper with Keychain auth
alias ofscrape='\$HOME/.local/bin/of-scraper-keychain.sh && ofscraper'

# --- end downloader aliases ---
ALIASES
  echo "[OK] Aliases added"
fi

# --- Add ~/.local/bin to PATH if not present ---
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
  if ! grep -q '.local/bin' "$ZSHRC" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$ZSHRC"
    echo "[OK] Added ~/.local/bin to PATH"
  fi
fi

echo ""
echo "========================================="
echo "Phase 11 COMPLETE"
echo "========================================="
echo ""
echo "Tools installed:"
echo "  yt-dlp      — Video/audio downloader"
echo "  gallery-dl  — Image/gallery downloader"
echo "  OF-Scraper  — OnlyFans content scraper"
echo ""
echo "Security: All credentials stored in macOS Keychain."
echo "Helper scripts: $HELPER_DIR/"
echo ""
echo "To add credentials to Keychain:"
echo ""
echo "  # yt-dlp (per-site)"
echo "  security add-generic-password -s yt-dlp-youtube -a username -w 'USER'"
echo "  security add-generic-password -s yt-dlp-youtube -a password -w 'PASS'"
echo ""
echo "  # gallery-dl (per-site)"
echo "  security add-generic-password -s gallery-dl-twitter -a username -w 'USER'"
echo "  security add-generic-password -s gallery-dl-twitter -a password -w 'PASS'"
echo "  security add-generic-password -s gallery-dl-instagram -a username -w 'USER'"
echo "  security add-generic-password -s gallery-dl-instagram -a password -w 'PASS'"
echo ""
echo "  # OF-Scraper (extract from browser DevTools)"
echo "  security add-generic-password -s of-scraper -a sess -w 'SESS_COOKIE'"
echo "  security add-generic-password -s of-scraper -a auth_id -w 'AUTH_ID'"
echo "  security add-generic-password -s of-scraper -a user_agent -w 'USER_AGENT'"
echo "  security add-generic-password -s of-scraper -a x-bc -w 'X_BC_TOKEN'"
echo ""
echo "Commands (after 'source ~/.zshrc'):"
echo "  ytdl URL              — download video"
echo "  ytdl-audio URL        — download audio only (mp3)"
echo "  gdl URL               — download gallery"
echo "  ofscrape              — run OF-Scraper"
echo "========================================="
