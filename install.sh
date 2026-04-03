#!/usr/bin/env bash
set -euo pipefail

# vivaldi-peek installer for macOS and Linux
# Installs auto-collapsing vertical tabs CSS for Vivaldi.
# Vivaldi must be CLOSED before running.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSS_SOURCE="$SCRIPT_DIR/css"

# ── Detect OS and paths ─────────────────────────────────────────────────────

case "$(uname -s)" in
    Darwin)
        VIVALDI_USER_DATA="$HOME/Library/Application Support/Vivaldi"
        ;;
    Linux)
        VIVALDI_USER_DATA="$HOME/.config/vivaldi"
        ;;
    *)
        echo "Error: Unsupported OS. Use install.ps1 on Windows."
        exit 1
        ;;
esac

PREFS_FILE="$VIVALDI_USER_DATA/Default/Preferences"
CSS_DEST="$VIVALDI_USER_DATA/vivaldi-peek-css"

# ── Preflight checks ────────────────────────────────────────────────────────

if [ ! -f "$PREFS_FILE" ]; then
    echo "Error: Vivaldi Preferences not found at $PREFS_FILE"
    echo "Is Vivaldi installed?"
    exit 1
fi

if pgrep -x "vivaldi" > /dev/null 2>&1 || pgrep -x "Vivaldi" > /dev/null 2>&1; then
    echo "Error: Vivaldi is currently running. Please close it first."
    exit 1
fi

# Require jq for JSON manipulation
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    echo "  macOS:  brew install jq"
    echo "  Linux:  sudo apt install jq  (or your package manager)"
    exit 1
fi

# ── Uninstall ────────────────────────────────────────────────────────────────

if [ "${1:-}" = "--uninstall" ] || [ "${1:-}" = "-u" ]; then
    echo "Uninstalling vivaldi-peek..."

    rm -rf "$CSS_DEST" && echo "  Removed $CSS_DEST"

    jq 'del(.vivaldi.features.css_mods) | del(.vivaldi.appearance.css_ui_mods_directory)' \
        "$PREFS_FILE" > "$PREFS_FILE.tmp" && mv "$PREFS_FILE.tmp" "$PREFS_FILE"
    echo "  Reverted Preferences"

    echo ""
    echo "vivaldi-peek uninstalled. Restart Vivaldi to see the change."
    exit 0
fi

# ── Install ──────────────────────────────────────────────────────────────────

echo ""
echo "  vivaldi-peek installer"
echo "  Auto-collapsing vertical tabs for Vivaldi"
echo ""

# Step 1: Copy CSS files
echo "[1/3] Copying CSS files..."
rm -rf "$CSS_DEST"
cp -r "$CSS_SOURCE" "$CSS_DEST"
echo "  -> $CSS_DEST"

# Step 2: Backup Preferences
echo "[2/3] Backing up Preferences..."
cp "$PREFS_FILE" "$PREFS_FILE.vivaldi-peek-backup"
echo "  -> $PREFS_FILE.vivaldi-peek-backup"

# Step 3: Update Preferences
echo "[3/3] Configuring Vivaldi..."

jq --arg cssdir "$CSS_DEST" '
    .vivaldi.features.css_mods = true |
    .vivaldi.appearance.css_ui_mods_directory = $cssdir
' "$PREFS_FILE" > "$PREFS_FILE.tmp" && mv "$PREFS_FILE.tmp" "$PREFS_FILE"

echo "  Enabled CSS modifications experiment flag"
echo "  Set CSS directory to: $CSS_DEST"

# ── Done ─────────────────────────────────────────────────────────────────────

echo ""
echo "vivaldi-peek installed!"
echo ""
echo "Next steps:"
echo "  1. Open Vivaldi"
echo "  2. Make sure your tabs are set to vertical (left or right side)"
echo "     Settings > Tabs > Tab Bar Position > Left or Right"
echo "  3. Your tabs will now auto-hide and reveal on hover"
echo ""
echo "To uninstall: ./install.sh --uninstall"
echo ""
