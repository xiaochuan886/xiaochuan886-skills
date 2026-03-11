#!/bin/bash
# WeChat Cell Writer - First-Time Setup Script
# This script installs all dependencies required by the skill

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "  WeChat Cell Writer - First-Time Setup"
echo "=========================================="
echo ""

# Check for package manager
if command -v bun &> /dev/null; then
    PKG_MANAGER="bun"
    INSTALL_CMD="bun install"
elif command -v npm &> /dev/null; then
    PKG_MANAGER="npm"
    INSTALL_CMD="npm install"
else
    echo "❌ Error: Neither bun nor npm found. Please install one of them first."
    echo "   安装 bun: curl -fsSL https://bun.sh/install | bash"
    echo "   安装 npm: brew install node"
    exit 1
fi

echo "✓ Using package manager: $PKG_MANAGER"
echo ""

# Install npm dependencies
echo "📦 Installing npm dependencies..."
cd "$SCRIPT_DIR"
$INSTALL_CMD
echo "✓ npm dependencies installed"
echo ""

# Check and install Playwright browsers
echo "🌐 Checking Playwright browsers..."
if npx playwright --version &> /dev/null; then
    echo "✓ Playwright is installed"

    # Check if chromium is installed
    if [ -d "$HOME/.cache/ms-playwright/chromium" ] || [ -d "$HOME/Library/Caches/ms-playwright/chromium" ]; then
        echo "✓ Chromium browser is already installed"
    else
        echo "📥 Installing Chromium browser for Playwright..."
        npx playwright install chromium
        echo "✓ Chromium installed"
    fi
else
    echo "📥 Installing Playwright and Chromium..."
    npx playwright install chromium
    echo "✓ Playwright and Chromium installed"
fi

echo ""
echo "=========================================="
echo "  ✅ Setup Complete!"
echo "=========================================="
echo ""
echo "You can now use the wechat-cell-writer skill."
echo ""
echo "Quick start commands:"
echo "  node ~/.agents/skills/wechat-cell-writer/scripts/run-workflow.js --step init --topic \"NK细胞\""
echo ""
