#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

if ps -axo comm= | grep -q '/iTerm.app/Contents/MacOS/iTerm2$'; then
  echo "Quit iTerm first (run this from Terminal.app)" >&2
  exit 1
fi

brew install --cask iterm2 font-commit-mono
brew install jq

defaults import com.googlecode.iterm2 com.googlecode.iterm2.plist

mkdir -p ~/.claude/hooks
cp -p claude/hooks/tab-status.sh ~/.claude/hooks/

settings=~/.claude/settings.json
[ -e "$settings" ] && cp "$settings" "$settings.bak" || echo '{}' > "$settings"
jq -s '.[1].hooks as $new | .[0] | .hooks = reduce ($new | keys[]) as $e (.hooks // {}; .[$e] = ((.[$e] // []) + $new[$e] | unique))' \
  "$settings" claude/tab-status-hooks.json > "$settings.tmp"
mv "$settings.tmp" "$settings"

echo "Done. Open iTerm."
