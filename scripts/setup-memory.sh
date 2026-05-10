#!/usr/bin/env bash
# setup-memory.sh
# Claude Code memory 同期戦略を対話的に設定するウィザード。
#
# Claude Code には2種類の memory があります:
#   1. User-level: ~/.claude/memory/
#   2. Project-level (auto-memory): ~/.claude/projects/-Users-<USERNAME>/memory/
#
# このスクリプトは (2) をどう扱うかを聞いて適切に設定します。

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
USERNAME="$(whoami)"
PROJECT_MEMORY_DIR="$HOME/.claude/projects/-Users-${USERNAME}/memory"
REPO_MEMORY_DIR="$REPO_ROOT/code/memory"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Claude Code Memory 同期セットアップ                          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Claude Code には2種類の memory があります:"
echo "  1. User-level memory  (~/.claude/memory/)"
echo "  2. Project-level auto-memory  (~/.claude/projects/-Users-<USER>/memory/)"
echo ""
echo "あなたの使い方はどれですか?"
echo ""
echo "  [A] 複数Macで同じプロジェクトを開発  (両方syncする) ←推奨"
echo "  [B] 各Macで別プロジェクトを開発     (user-levelだけsync)"
echo "  [C] とりあえずスキップ              (後で再実行可)"
echo ""

if [[ -d "$PROJECT_MEMORY_DIR" && ! -L "$PROJECT_MEMORY_DIR" ]]; then
  count=$(find "$PROJECT_MEMORY_DIR" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')
    echo "  ※ 現在 $PROJECT_MEMORY_DIR に $count ファイル存在します"
      echo ""
      fi

      read -p "選択 (A/B/C): " choice
      echo ""

      case "$choice" in
        A|a)
            echo "▶ project-level memory を claude-config に統合します..."

                if [[ -L "$PROJECT_MEMORY_DIR" ]]; then
                      target=$(readlink "$PROJECT_MEMORY_DIR")
                            if [[ "$target" == "$REPO_MEMORY_DIR" ]]; then
                                    echo "  ✓ 既に正しい symlink になっています"
                                            exit 0
                                                  else
                                                          echo "  ⚠ 別の場所への symlink を検出: $target"
                                                                  echo "  → 上書きしてもよいですか? (y/N): "
                                                                          read -r confirm
                                                                                  [[ "$confirm" == "y" ]] || { echo "中止しました"; exit 1; }
                                                                                          rm "$PROJECT_MEMORY_DIR"
                                                                                                fi
                                                                                                    elif [[ -d "$PROJECT_MEMORY_DIR" ]]; then
                                                                                                          backup="${PROJECT_MEMORY_DIR}.backup-$(date +%Y%m%d-%H%M%S)"
                                                                                                                echo "  → 既存ファイルを退避: $backup"
                                                                                                                      mv "$PROJECT_MEMORY_DIR" "$backup"
                                                                                                                      
                                                                                                                            echo "  → 退避ファイルを claude-config に取り込みます (重複は既存優先)"
                                                                                                                                  mkdir -p "$REPO_MEMORY_DIR"
                                                                                                                                        cp -n "$backup"/* "$REPO_MEMORY_DIR/" 2>/dev/null || true
                                                                                                                                            fi
                                                                                                                                            
                                                                                                                                                mkdir -p "$(dirname "$PROJECT_MEMORY_DIR")"
                                                                                                                                                    ln -s "$REPO_MEMORY_DIR" "$PROJECT_MEMORY_DIR"
                                                                                                                                                        echo "  ✅ symlink 作成: $PROJECT_MEMORY_DIR → $REPO_MEMORY_DIR"
                                                                                                                                                            echo ""
                                                                                                                                                                echo "  → 'claude-sync' で他Macに反映してください"
                                                                                                                                                                    ;;
                                                                                                                                                                    
                                                                                                                                                                      B|b)
                                                                                                                                                                          echo "▶ project-level memory はローカル管理のままにします"
                                                                                                                                                                              echo "  ⚠ 各Macに溜まった auto-memory は他Macに同期されません"
                                                                                                                                                                                  ;;
                                                                                                                                                                                  
                                                                                                                                                                                    C|c)
                                                                                                                                                                                        echo "スキップしました。後で再実行する場合:"
                                                                                                                                                                                            echo "  $0"
                                                                                                                                                                                                ;;
                                                                                                                                                                                                
                                                                                                                                                                                                  *)
                                                                                                                                                                                                      echo "❌ 無効な選択です"
                                                                                                                                                                                                          exit 1
                                                                                                                                                                                                              ;;
                                                                                                                                                                                                              esac
                                                                                                                                                                                                              
                                                                                                                                                                                                              echo ""
                                                                                                                                                                                                              echo "✅ memory セットアップ完了"
                                                                                                                                                                                                              
