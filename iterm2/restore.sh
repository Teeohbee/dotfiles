#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

if ps -axo comm= | grep -q '/iTerm.app/Contents/MacOS/iTerm2$'; then
  echo "Quit iTerm first (run this from Terminal.app)" >&2
  exit 1
fi

brew install --cask iterm2 font-commit-mono

defaults import com.googlecode.iterm2 com.googlecode.iterm2.plist

echo "Done. Open iTerm."
