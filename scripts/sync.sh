#!/usr/bin/env bash
# sync.sh
# ローカル変更を commit → リモートを pull → push する。
# 作業終わりや「学習を反映させたい」タイミングで実行する。
#
# Usage: ./scripts/sync.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

HOSTNAME_SHORT="$(hostname -s)"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

# 1. ローカル変更を staging
git add -A

# 2. 変更があればコミット
if git diff --cached --quiet; then
  echo "📭 ローカルに新しい変更はありません"
else
  git commit -m "sync: ${HOSTNAME_SHORT} @ ${TIMESTAMP}" >/dev/null
  echo "✅ committed local changes"
fi

# 3. リモートを pull（rebase で履歴を直線に保つ）
echo "⬇  pulling remote..."
if ! git pull --rebase --autostash; then
  echo
  echo "❌ rebase conflict が発生しました"
  echo "   1) git status で衝突ファイルを確認"
  echo "   2) ファイルを編集して衝突を解決"
  echo "   3) git add <ファイル>"
  echo "   4) git rebase --continue"
  echo "   5) もう一度 ./scripts/sync.sh を実行"
  exit 1
fi

# 4. push
echo "⬆  pushing..."
git push

echo
echo "🎉 sync 完了 ($HOSTNAME_SHORT)"
