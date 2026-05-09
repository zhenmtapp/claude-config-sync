#!/usr/bin/env bash
# install.sh
# 実ファイル位置 (~/.claude/, ~/Library/Application Support/Claude/) から
# このリポジトリへのシンボリックリンクを張る。既存ファイルは自動でバックアップ。
#
# Usage:
#   ./scripts/install.sh              # 全部
#   ./scripts/install.sh --cli-only   # CLI のみ
#   ./scripts/install.sh --desktop-only

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="$HOME/.claude-config-backups/$(date +%Y%m%d-%H%M%S)"

CLI_DIR="$HOME/.claude"
DESKTOP_DIR="$HOME/Library/Application Support/Claude"

# init-from-existing.sh と同じリストを保つこと
CLI_ITEMS=(
  "skills"
  "memory"
  "CLAUDE.md"
  "settings.json"
  "hooks"
)

DESKTOP_ITEMS=(
  "claude_desktop_config.json"
)

mode="${1:---all}"

backup_and_link() {
  local real_path="$1"
  local repo_path="$2"

  if [[ ! -e "$repo_path" ]]; then
    echo "  ⚠ skip (repo source missing): $repo_path"
    return
  fi

  # すでに同じリンクが張られていればスキップ
  if [[ -L "$real_path" ]]; then
    local current_target
    current_target="$(readlink "$real_path")"
    if [[ "$current_target" == "$repo_path" ]]; then
      echo "  ✓ already linked: $real_path"
      return
    fi
    echo "  → updating symlink: $real_path"
    rm "$real_path"
  elif [[ -e "$real_path" ]]; then
    mkdir -p "$BACKUP_DIR"
    echo "  → backing up: $(basename "$real_path") → $BACKUP_DIR/"
    mv "$real_path" "$BACKUP_DIR/"
  fi

  mkdir -p "$(dirname "$real_path")"
  ln -s "$repo_path" "$real_path"
  echo "  ✅ linked: $real_path → $repo_path"
}

if [[ "$mode" == "--all" || "$mode" == "--cli-only" ]]; then
  echo "▶ Claude Code (CLI) のシンボリックリンクを設定中..."
  mkdir -p "$CLI_DIR"
  for item in "${CLI_ITEMS[@]}"; do
    backup_and_link "$CLI_DIR/$item" "$REPO_ROOT/code/$item"
  done
fi

if [[ "$mode" == "--all" || "$mode" == "--desktop-only" ]]; then
  echo
  echo "▶ Claude Desktop / Cowork のシンボリックリンクを設定中..."
  mkdir -p "$DESKTOP_DIR"
  for item in "${DESKTOP_ITEMS[@]}"; do
    backup_and_link "$DESKTOP_DIR/$item" "$REPO_ROOT/desktop/$item"
  done
fi

echo
echo "✅ Done"
if [[ -d "$BACKUP_DIR" ]]; then
  echo "📦 バックアップ: $BACKUP_DIR"
fi
echo
echo "次のステップ:"
echo "  - Claude Desktop を一度終了 (Cmd+Q) して再起動すると、新しい設定が読み込まれます"
echo "  - 自動同期を有効化: README.md の「3. 自動同期を有効化」を参照"
echo "  - .zshrc に snippet を追加: cat templates/zshrc-snippet.sh >> ~/.zshrc"
