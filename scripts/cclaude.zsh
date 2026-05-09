# cclaude.zsh
# Claude Config Sync の状況を1コマンドで確認する関数。
# .zshrc から source する想定:
#   source $HOME/git/claude-config/scripts/cclaude.zsh

cclaude() {
  local repo="${CLAUDE_CONFIG_REPO:-$HOME/git/claude-config}"

  cd "$repo" 2>/dev/null || { echo "リポジトリが見つかりません: $repo"; return 1; }

  echo "📍 $(pwd)"
  echo ""
  echo "=== 同期状態 ==="
  git fetch --quiet 2>/dev/null
  local ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "?")
  local behind=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo "?")
  local dirty=$(git status --porcelain | wc -l | tr -d ' ')
  echo "  unpushed:    $ahead commits"
  echo "  unpulled:    $behind commits"
  echo "  uncommitted: $dirty files"
  echo ""
  echo "=== 直近の auto-sync ログ ==="
  tail -5 .auto-sync.log 2>/dev/null || echo "  (ログなし)"
  echo ""
  echo "=== 困ったら ==="
  echo "  open $repo/docs/CHEATSHEET.md"
  cd - > /dev/null
}
