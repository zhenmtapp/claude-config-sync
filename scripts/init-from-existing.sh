#!/usr/bin/env bash
# init-from-existing.sh
# 既存の Claude 設定をリポジトリにコピーする（初回マスター側で1回だけ実行）
#
# Usage: ./scripts/init-from-existing.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

CLI_DIR="$HOME/.claude"
DESKTOP_DIR="$HOME/Library/Application Support/Claude"

# 同期対象（追加したい項目があればここに足す）
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

copy_item() {
  local src="$1"
  local dst_dir="$2"
  local name
  name="$(basename "$src")"

  if [[ ! -e "$src" ]]; then
    echo "  ⚠ skip (not found): $src"
    return
  fi

  if [[ -L "$src" ]]; then
    echo "  ⚠ skip (already a symlink): $src"
    return
  fi

  echo "  → copying: $name"
  rm -rf "$dst_dir/$name"
  cp -R "$src" "$dst_dir/"
}

echo "▶ Claude Code (CLI) の設定をコピー中..."
mkdir -p "$REPO_ROOT/code"
for item in "${CLI_ITEMS[@]}"; do
  copy_item "$CLI_DIR/$item" "$REPO_ROOT/code"
done

echo
echo "▶ Claude Desktop / Cowork の設定をコピー中..."
mkdir -p "$REPO_ROOT/desktop"
for item in "${DESKTOP_ITEMS[@]}"; do
  copy_item "$DESKTOP_DIR/$item" "$REPO_ROOT/desktop"
done

echo
echo "✅ コピー完了"
echo
echo "次にやること:"
echo "  1. 'git status' で内容を確認（特に認証情報が混入していないか）"
echo "  2. 'git add -A && git commit -m \"initial\"'"
echo "  3. GitHub のプライベートリポジトリにpush"
echo "  4. './scripts/install.sh' で実体ファイルをシンボリックリンクに置き換え"
