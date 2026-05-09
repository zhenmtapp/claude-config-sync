---
name: sync-check
description: 複数Mac間でのClaude Config Sync (~/git/claude-config) の同期状態と健全性を網羅的にチェックするスキル。リポジトリのgit状態 (unpushed/unpulled/uncommitted)、シンボリックリンクの整合性、launchd auto-sync ジョブの稼働状況、~/.claude/settings.local.json の存在、enabledPlugins と実インストール状況の差分などを一括確認し、問題があれば該当する修復コマンドを提示する。「同期確認」「sync確認」「sync状態」「claude-config確認」「configステータス」「設定反映されてる?」「ちゃんと同期されてる?」「両PCの状態確認」「シンボリックリンク確認」「launchd動いてる?」「auto-sync動いてる?」「configチェック」「config diagnose」「sync-check」「/sync-check」「/claude-config-check」「同期トラブル」「sync trouble」「リポジトリ状態」といったキーワードが出たら必ずこのスキルを使うこと。Claude Config Sync 関連で「動いてる?」「ちゃんとなってる?」と聞かれた場合や、シンボリックリンク・launchd・git pull/push の状況を確認したいときには、明示的な指示がなくても積極的にトリガーすること。
---

# sync-check スキル

複数Mac間でClaude設定を同期する仕組み (`~/git/claude-config` リポジトリ) が正しく稼働しているかを確認するスキル。

## 実行手順

1. このスキルディレクトリの `scripts/check.sh` を Bash で実行する
   ```bash
   bash ~/.claude/skills/sync-check/scripts/check.sh
   ```

2. 出力を上から順に読み、各セクションの ✅ / ⚠ / ❌ を確認

3. ❌ や ⚠ があれば、下の「修復パターン早見表」を見て該当する修復コマンドをユーザーに提示

4. 全部 ✅ なら「同期は正常稼働中」と簡潔に伝える

## チェック項目

| セクション | 何を見る |
|---|---|
| Git 状態 | unpushed / unpulled / uncommitted の数 |
| シンボリックリンク | `~/.claude/{skills,memory,hooks,CLAUDE.md,settings.json}` と `~/Library/Application Support/Claude/claude_desktop_config.json` がリポジトリへのリンクになっているか |
| launchd auto-sync | `com.user.claude-config-sync` がロードされているか、plistが存在するか |
| auto-sync スクリプト | `scripts/auto-sync.sh` に実行権限があるか |
| 直近のログ | `.auto-sync.log` の最終5行 |
| マシン固有設定 | `~/.claude/settings.local.json` の有無 |
| プラグイン | `enabledPlugins` の一覧 |

## 修復パターン早見表

| 症状 | 修復コマンド |
|---|---|
| `unpushed > 0` | `claude-sync` |
| `unpulled > 0` | `cd ~/git/claude-config && git pull` |
| `uncommitted > 0` | `cd ~/git/claude-config && git status` で内容確認 → `claude-sync` |
| シンボリックリンクが ❌ / ⚠ | `cd ~/git/claude-config && ./scripts/install.sh` |
| launchd ❌ 未登録 | README.md「3. 自動同期を有効化」セクション参照 |
| auto-sync.sh 実行権限なし | `chmod +x ~/git/claude-config/scripts/auto-sync.sh` |
| rebase conflict | `cd ~/git/claude-config && git status` → 衝突解決 → `git rebase --continue` |
| `enabledPlugins` と実インストールが食い違う | Claude Code の `/plugin` から不足分を追加 |

## 出力フォーマットの注意

- スクリプト出力は等幅フォント表示が前提。コードブロックで囲んで表示する
- 問題が複数ある場合は、優先度順（git → symlink → launchd の順）で対処を案内する
- 詳細は `~/git/claude-config/docs/CHEATSHEET.md` を参照させる

## このスキル自体の保存場所

- `~/.claude/skills/sync-check/` （これは `~/git/claude-config/code/skills/sync-check/` へのリポジトリ経由symlink）
- 編集したい場合はリポジトリ側を編集して `claude-sync`
