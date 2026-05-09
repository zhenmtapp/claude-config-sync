# Troubleshooting

よくある問題と対処法。

---

## ❌ `git clone` で SSH key 認証エラー

```
Permission denied (publickey).
```

SSH鍵が GitHub に登録されていません。HTTPSに切り替えるのが早いです：

```bash
git clone https://github.com/YOUR_USER/YOUR_REPO.git ~/git/claude-config
```

push時にユーザー名と Personal Access Token (PAT) を求められます。PAT は <https://github.com/settings/tokens/new> で `repo` スコープで作成できます。

毎回入力したくなければ：

```bash
git config --global credential.helper osxkeychain
```

---

## ❌ `init-from-existing.sh` で「skip (already a symlink)」が出る

すでに `install.sh` が走った後の状態です。`init-from-existing.sh` は **初回マスター側で1回だけ** 実行するスクリプトなので、2回目以降は実行しないでください。

---

## ❌ `install.sh` 後に Claude Code が起動しない / 設定を読まない

Claude Code を完全に終了してから再起動してください：

```bash
# Claude Code CLI が起動中なら一度全部終了
pkill -f claude
```

シンボリックリンクが正しく張られているか確認：

```bash
ls -la ~/.claude/
```

`->` 矢印付きで `~/git/claude-config/code/...` を指していれば成功。

---

## ❌ `claude-sync` で `Cannot rebase onto multiple branches` エラー

`pull.sh` を `.zshrc` のバックグラウンドで動かしている場合、`claude-sync` と競合することがあります。

修正：`.zshrc` から `pull.sh` のバックグラウンド起動行をコメントアウトしてください。30分ごとの auto-sync で十分です。

```bash
# .zshrc の以下のような行をコメントアウト:
#   [ -d "$CLAUDE_CONFIG_REPO" ] && "$CLAUDE_CONFIG_REPO/scripts/pull.sh" &
```

復旧：

```bash
cd ~/git/claude-config
git rebase --abort 2>/dev/null
git pull origin main
git push origin main
```

---

## ❌ launchd ジョブが動いていない

```bash
# 状態確認
launchctl list | grep claude-config

# ログ確認 (エラーがあれば見える)
cat /tmp/claude-config-sync.err
tail ~/git/claude-config/.auto-sync.log
```

未登録なら再ロード：

```bash
launchctl unload ~/Library/LaunchAgents/com.user.claude-config-sync.plist 2>/dev/null
launchctl load ~/Library/LaunchAgents/com.user.claude-config-sync.plist
```

plistファイル自体が無い場合は README.md の「3. 自動同期を有効化」を再実行してください。

---

## ❌ シンボリックリンクが壊れた / リンクが想定外

```bash
# 現状確認
ls -la ~/.claude/

# 壊れたリンクを削除して再構築
rm -f ~/.claude/{skills,memory,hooks,CLAUDE.md,settings.json}
cd ~/git/claude-config
./scripts/install.sh
```

---

## ❌ プラグインが認識されない

`enabledPlugins` 設定はリポジトリ経由で同期されますが、プラグイン本体は各PCで個別インストールが必要です。

Claude Code を起動して `/plugin` から該当のプラグインを追加してください。

---

## ❌ 2台目で Claude Desktop の設定が反映されない

Claude Desktop は起動中の設定をキャッシュします。**一度完全に終了 (Cmd+Q) してから再起動**してください。

---

## ⚠️ "permission denied" が頻発するようになった

`~/.claude/settings.json` の `defaultMode` が `bypassPermissions` でなくなった可能性。

`~/.claude/settings.local.json` がuser-levelで効かない場合は、各プロジェクト直下の `.claude/settings.local.json` に permissions を移してください。

---

## ⚠️ 同期した skill が他のPCで動かない

skill が **シンボリックリンク（プラグイン管理のもの）** の場合、他PCでは元のリンク先が存在しないため動きません。

- 解決策: 該当プラグインを他PCにもインストール（プラグインが symlink を再生成する）
- または: `.gitignore` で symlink skill を除外（リポジトリで管理しない）

---

## それでも解決しない場合

1. `cclaude` でステータス全体を確認
2. Claude Code に「同期確認して」と聞く（sync-check スキルが詳細診断＋修復コマンドを提示）
3. `~/git/claude-config/.auto-sync.log` を確認
4. `/tmp/claude-config-sync.{out,err}` を確認
