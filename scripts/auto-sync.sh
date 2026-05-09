#!/usr/bin/env bash
# auto-sync.sh
# launchd から呼ばれる自動同期スクリプト。
# 衝突時は中断して macOS 通知。失敗してもターミナル操作を妨げない。
#
# Manual usage: ./scripts/auto-sync.sh

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG="$REPO_ROOT/.auto-sync.log"

cd "$REPO_ROOT" || exit 0

# rebase が中断状態なら何もしない
if [[ -d ".git/rebase-merge" || -d ".git/rebase-apply" ]]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') rebase進行中、スキップ" >> "$LOG"
  exit 0
fi

{
  echo ""
  echo "=== $(date '+%Y-%m-%d %H:%M:%S') auto-sync ==="

  # ローカル変更を staging
  git add -A

  # 変更があればコミット
  if ! git diff --cached --quiet; then
    git commit -m "auto-sync: $(hostname -s) @ $(date '+%Y-%m-%d %H:%M:%S')" >/dev/null
    echo "✓ commit"
  fi

  # pull
  if ! git pull --rebase --autostash 2>&1; then
    echo "❌ rebase conflict"
    /usr/bin/osascript -e 'display notification "Claude Config: 衝突発生。cd ~/git/claude-config && git status で確認してください" with title "Claude Config Sync"' 2>/dev/null
    exit 1
  fi

  # push
  if ! git push 2>&1; then
    echo "⚠ push失敗（ネットワーク不通など）"
    exit 0
  fi

  echo "✓ done"
} >> "$LOG" 2>&1

# ログが大きくなりすぎたら切り詰める（直近500行のみ保持）
if [[ -f "$LOG" ]] && [[ $(wc -l < "$LOG") -gt 500 ]]; then
  tail -500 "$LOG" > "${LOG}.tmp" && mv "${LOG}.tmp" "$LOG"
fi
