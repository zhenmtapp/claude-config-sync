
# === Claude Config Sync ===
# このブロックを ~/.zshrc に追加してください:
#   cat templates/zshrc-snippet.sh >> ~/.zshrc

export CLAUDE_CONFIG_REPO="$HOME/git/claude-config"

# 同期コマンド (commit + pull + push)
alias claude-sync='"$CLAUDE_CONFIG_REPO/scripts/sync.sh"'

# ステータス確認関数 (cclaude)
[ -f "$CLAUDE_CONFIG_REPO/scripts/cclaude.zsh" ] && source "$CLAUDE_CONFIG_REPO/scripts/cclaude.zsh"
