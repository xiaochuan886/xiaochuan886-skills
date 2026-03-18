#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "  OPC Community Writer - First-Time Setup"
echo "=========================================="
echo ""

if command -v bun &> /dev/null; then
    PKG_MANAGER="bun"
    INSTALL_CMD="bun install"
elif command -v npm &> /dev/null; then
    PKG_MANAGER="npm"
    INSTALL_CMD="npm install"
else
    echo "Error: Neither bun nor npm found. Please install one of them first."
    exit 1
fi

echo "Using package manager: $PKG_MANAGER"
echo ""

echo "Installing npm dependencies..."
cd "$SCRIPT_DIR"
$INSTALL_CMD
echo "Dependencies installed"
echo ""

echo "Checking Playwright browsers..."
if npx playwright --version &> /dev/null; then
    if [ -d "$HOME/.cache/ms-playwright/chromium" ] || [ -d "$HOME/Library/Caches/ms-playwright/chromium" ]; then
        echo "Chromium browser is already installed"
    else
        npx playwright install chromium
        echo "Chromium installed"
    fi
else
    npx playwright install chromium
    echo "Playwright and Chromium installed"
fi

echo ""
echo "Setup complete"
echo ""
echo "Quick start:"
echo "  node ~/.agents/skills/opc-community-writer/scripts/run-workflow.js --step init --topic \"为什么 AI 时代一人公司值得重新理解\""
