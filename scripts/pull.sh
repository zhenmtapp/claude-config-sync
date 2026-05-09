#!/usr/bin/env bash
# pull.sh
# リモートの最新を静かに取得する（オプション機能）。
#
# 注意: launchd auto-sync を使う場合、これをシェル起動時に実行すると
# 衝突する可能性があるため非推奨。緊急時の手動pull用としてのみ使用してください。
#
# Usage: ./scripts/pull.sh

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 0

git pull --rebase --autostash --quiet 2>/dev/null || true
