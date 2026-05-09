#!/usr/bin/env bash
# check.sh - Claude Config Sync 状態確認 + 自動対策提示
#
# 各チェック項目を ✅ / ⚠ / ❌ で表示し、❌/⚠ には即座に修復コマンドを提示する。
# 最後に「今すぐ実行すべきコマンド」を集約して出力する。

REPO="${CLAUDE_CONFIG_REPO:-$HOME/git/claude-config}"
HOSTNAME_SHORT="$(hostname -s)"

# 検出された修復コマンドを蓄積する配列
FIXES=()

print_header() {
  echo ""
  echo "================================================================"
  echo " 🔍 Claude Config Sync ステータス: $HOSTNAME_SHORT"
  echo "================================================================"
}

print_footer() {
  echo ""
  echo "================================================================"
  if [[ ${#FIXES[@]} -eq 0 ]]; then
    echo " ✅ すべて正常です。何もする必要はありません。"
  else
    echo " ⚠ ${#FIXES[@]} 件の問題が見つかりました。次のコマンドで対処できます:"
    echo ""
    for fix in "${FIXES[@]}"; do
      echo "   $fix"
    done
    echo ""
    echo " 詳細は: open $REPO/docs/CHEATSHEET.md"
  fi
  echo "================================================================"
}

print_header

# -----------------------------------------------------------
# 0. リポジトリの存在確認
# -----------------------------------------------------------
if [[ ! -d "$REPO" ]]; then
  echo ""
  echo "❌ リポジトリが見つかりません: $REPO"
  echo ""
  echo "  → セットアップ手順:"
  echo "    git clone <あなたのリポジトリURL> ~/git/claude-config"
  echo "    cd ~/git/claude-config && ./scripts/install.sh"
  exit 1
fi

cd "$REPO"

# -----------------------------------------------------------
# 1. Git 状態
# -----------------------------------------------------------
echo ""
echo "■ Git 状態"
git fetch --quiet 2>/dev/null
ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "?")
behind=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo "?")
dirty=$(git status --porcelain | wc -l | tr -d ' ')

if [[ "$ahead" == "0" && "$behind" == "0" && "$dirty" == "0" ]]; then
  echo "  ✅ unpushed: 0 / unpulled: 0 / uncommitted: 0"
else
  echo "  ⚠ unpushed: $ahead / unpulled: $behind / uncommitted: $dirty"
  if [[ "$dirty" != "0" ]]; then
    echo ""
    echo "  未コミットのファイル:"
    git status --short | head -10 | sed 's/^/    /'
    FIXES+=("claude-sync                    # 未コミット変更をsync")
  fi
  if [[ "$behind" != "0" && "$dirty" == "0" ]]; then
    FIXES+=("cd $REPO && git pull           # リモート変更を取り込み")
  fi
  if [[ "$ahead" != "0" && "$behind" == "0" && "$dirty" == "0" ]]; then
    FIXES+=("cd $REPO && git push           # ローカルcommitをpush")
  fi
fi

# -----------------------------------------------------------
# 2. シンボリックリンク整合性
# -----------------------------------------------------------
echo ""
echo "■ シンボリックリンク"

LINK_BROKEN=0
check_link() {
  local path="$1"
  local expected="$2"
  if [[ ! -L "$path" ]]; then
    if [[ -e "$path" ]]; then
      echo "  ⚠ $(basename "$path") (シンボリックリンクではない通常ファイル/ディレクトリ)"
    else
      echo "  ❌ $(basename "$path") (存在しない)"
    fi
    LINK_BROKEN=1
  elif [[ "$(readlink "$path")" == "$expected" ]]; then
    echo "  ✅ $(basename "$path")"
  else
    echo "  ⚠ $(basename "$path") → $(readlink "$path")"
    echo "      期待: $expected"
    LINK_BROKEN=1
  fi
}

check_link "$HOME/.claude/skills" "$REPO/code/skills"
check_link "$HOME/.claude/memory" "$REPO/code/memory"
check_link "$HOME/.claude/hooks" "$REPO/code/hooks"
check_link "$HOME/.claude/CLAUDE.md" "$REPO/code/CLAUDE.md"
check_link "$HOME/.claude/settings.json" "$REPO/code/settings.json"
check_link "$HOME/Library/Application Support/Claude/claude_desktop_config.json" "$REPO/desktop/claude_desktop_config.json"

if [[ $LINK_BROKEN -eq 1 ]]; then
  FIXES+=("cd $REPO && ./scripts/install.sh   # シンボリックリンクを再構築")
fi

# -----------------------------------------------------------
# 3. launchd auto-sync
# -----------------------------------------------------------
echo ""
echo "■ launchd auto-sync"

LAUNCHD_OK=1
PLIST="$HOME/Library/LaunchAgents/com.user.claude-config-sync.plist"

if [[ -f "$PLIST" ]]; then
  echo "  ✅ plist あり: $PLIST"
else
  echo "  ❌ plist なし: $PLIST"
  LAUNCHD_OK=0
fi

if launchctl list | grep -q "com.user.claude-config-sync"; then
  job_line=$(launchctl list | grep "com.user.claude-config-sync")
  exit_code=$(echo "$job_line" | awk '{print $2}')
  if [[ "$exit_code" == "0" || "$exit_code" == "-" ]]; then
    echo "  ✅ launchd 稼働中: $job_line"
  else
    echo "  ⚠ launchd ロード済みだが直近実行で終了コード $exit_code: $job_line"
    FIXES+=("tail -20 /tmp/claude-config-sync.err  # エラーログ確認")
  fi
else
  echo "  ❌ launchd ジョブが未登録"
  LAUNCHD_OK=0
fi

if [[ $LAUNCHD_OK -eq 0 ]]; then
  FIXES+=("# launchd未登録 → README.mdの「3. 自動同期を有効化」セクション参照")
  FIXES+=("open $REPO/README.md")
fi

# -----------------------------------------------------------
# 4. auto-sync スクリプト
# -----------------------------------------------------------
echo ""
echo "■ auto-sync スクリプト"

if [[ -x "$REPO/scripts/auto-sync.sh" ]]; then
  echo "  ✅ scripts/auto-sync.sh 実行可能"
elif [[ -f "$REPO/scripts/auto-sync.sh" ]]; then
  echo "  ⚠ scripts/auto-sync.sh 実行権限なし"
  FIXES+=("chmod +x $REPO/scripts/auto-sync.sh   # 実行権限を付与")
else
  echo "  ❌ scripts/auto-sync.sh が存在しない"
  FIXES+=("cd $REPO && git pull   # auto-sync.sh をリポジトリから取得")
fi

# -----------------------------------------------------------
# 5. 直近の auto-sync ログ
# -----------------------------------------------------------
echo ""
echo "■ 直近の auto-sync ログ (最終5行)"

if [[ -f "$REPO/.auto-sync.log" ]]; then
  tail -5 "$REPO/.auto-sync.log" | sed 's/^/  /'

  # 最後のログが何分前か
  if command -v stat >/dev/null 2>&1; then
    last_mod=$(stat -f "%m" "$REPO/.auto-sync.log" 2>/dev/null)
    now=$(date +%s)
    if [[ -n "$last_mod" ]]; then
      diff_min=$(( (now - last_mod) / 60 ))
      if [[ $diff_min -lt 60 ]]; then
        echo "  → 最終更新: ${diff_min}分前"
      elif [[ $diff_min -lt 1440 ]]; then
        echo "  → 最終更新: $((diff_min / 60))時間前"
      else
        echo "  ⚠ 最終更新: $((diff_min / 1440))日前 (auto-syncが止まっているかも)"
        FIXES+=("$REPO/scripts/auto-sync.sh   # 手動で1回実行して動作確認")
      fi
    fi
  fi
else
  echo "  (ログなし。auto-syncがまだ1回も走っていません)"
  FIXES+=("$REPO/scripts/auto-sync.sh   # 手動で1回実行してログ生成")
fi

# -----------------------------------------------------------
# 6. マシン固有設定
# -----------------------------------------------------------
echo ""
echo "■ マシン固有設定 (settings.local.json)"

if [[ -f "$HOME/.claude/settings.local.json" ]]; then
  echo "  ✅ ~/.claude/settings.local.json あり"
  if command -v python3 >/dev/null 2>&1; then
    keys=$(python3 -c "
import json
try:
    d = json.load(open('$HOME/.claude/settings.local.json'))
    paths = []
    if 'permissions' in d:
        if 'allow' in d['permissions']:
            paths.append(f\"  permissions.allow: {len(d['permissions']['allow'])} 件\")
        if 'additionalDirectories' in d['permissions']:
            paths.append(f\"  additionalDirectories: {len(d['permissions']['additionalDirectories'])} 件\")
    print('\n'.join(paths))
except Exception as e:
    print(f'  (パース失敗: {e})')
" 2>/dev/null)
    [[ -n "$keys" ]] && echo "$keys" | sed 's/^/    /'
  fi
else
  echo "  ℹ なし (このマシン固有のpermission設定がなければ正常)"
fi

# -----------------------------------------------------------
# 7. enabledPlugins
# -----------------------------------------------------------
echo ""
echo "■ プラグイン設定"

if [[ -f "$HOME/.claude/settings.json" ]] && command -v python3 >/dev/null 2>&1; then
  enabled=$(python3 -c "
import json
try:
    d = json.load(open('$HOME/.claude/settings.json'))
    print('\n'.join(d.get('enabledPlugins', {}).keys()))
except Exception:
    pass
" 2>/dev/null)
  if [[ -n "$enabled" ]]; then
    echo "  enabledPlugins (settings.json):"
    echo "$enabled" | sed 's/^/    - /'
    echo "  ※ 実インストール状況は Claude Code の /plugin で確認"
  else
    echo "  (enabledPlugins の登録なし)"
  fi
fi

# -----------------------------------------------------------
# まとめ
# -----------------------------------------------------------
print_footer
