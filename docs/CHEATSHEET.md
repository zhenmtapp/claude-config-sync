# Claude Config Sync — 運用チートシート

## 🎯 これだけ覚えればOK

- **何もしない** → 30分ごとに自動同期される（launchd）
- **今すぐ同期したい** → `claude-sync`
- **状況を確認したい** → `cclaude`
- **困ったらこのファイルを開く** → `open ~/git/claude-config/docs/CHEATSHEET.md`
- **Claude に状態確認を頼む** → 「同期確認して」「/sync-check」

---

## ⚡ よくある操作

| やりたいこと | コマンド |
|---|---|
| 手動で今すぐ同期 | `claude-sync` |
| 同期状態を確認 | `cclaude` |
| 最新を取得（pull だけ） | `cd ~/git/claude-config && git pull` |
| 自動同期を一時停止 | `launchctl unload ~/Library/LaunchAgents/com.user.claude-config-sync.plist` |
| 自動同期を再開 | `launchctl load ~/Library/LaunchAgents/com.user.claude-config-sync.plist` |
| 自動同期のログを見る | `tail -f ~/git/claude-config/.auto-sync.log` |

---

## 🚨 トラブルシューティング

### 「sync で rebase conflict が出た」

```bash
cd ~/git/claude-config
git status                 # ← どのファイルが衝突しているか確認
# 該当ファイルをエディタで開いて衝突マーカー (<<<<<<< 〜 >>>>>>>) を解決
git add <衝突したファイル>
git rebase --continue
claude-sync                # ← もう一度syncで完了
```

### 「シンボリックリンクが壊れた / 通常ファイルに戻したい」

```bash
# 壊れたリンクを削除
rm ~/.claude/skills

# リポジトリの内容で再作成
cd ~/git/claude-config
./scripts/install.sh
```

### 「permission denied が出るようになった (bypass モード OFF時)」

`~/.claude/settings.local.json` がuser-levelで効かない場合は、プロジェクト直下の `.claude/settings.local.json` に移す：

```bash
mkdir -p <プロジェクトのpath>/.claude
cat > <プロジェクトのpath>/.claude/settings.local.json <<'EOF'
{
  "permissions": {
    "allow": [
      "Read(<プロジェクトのpath>/**)"
    ]
  }
}
EOF
```

### 「自動同期が止まっているっぽい」

```bash
# ログ確認
tail -50 ~/git/claude-config/.auto-sync.log

# launchdジョブが生きているか
launchctl list | grep claude-config

# 出ない場合は再ロード
launchctl unload ~/Library/LaunchAgents/com.user.claude-config-sync.plist 2>/dev/null
launchctl load ~/Library/LaunchAgents/com.user.claude-config-sync.plist
```

### 「Claude Code でプラグインが認識されない (新規Macで)」

`settings.json` の `enabledPlugins` には記載されているが、プラグイン本体が未インストール。Claude Code を起動して `/plugin` から該当プラグインを追加する。

---

## 🗂 ファイル位置メモ

- リポジトリ: `~/git/claude-config/`
- Claude Code 設定（symlink）: `~/.claude/{skills,memory,hooks,CLAUDE.md,settings.json}`
- マシン固有設定: `~/.claude/settings.local.json` (リポジトリには含まれない)
- Claude Desktop 設定（symlink）: `~/Library/Application Support/Claude/claude_desktop_config.json`
- 自動同期スクリプト: `~/git/claude-config/scripts/auto-sync.sh`
- launchd プリスト: `~/Library/LaunchAgents/com.user.claude-config-sync.plist`
- 自動同期ログ: `~/git/claude-config/.auto-sync.log`
- バックアップ: `~/.claude-config-backups/<日時>/`

---

## 🔁 同期の挙動まとめ

| 状況 | 何が起きる |
|---|---|
| 30分ごと（自動） | リモートをpull → ローカル変更があればcommit → push |
| `claude-sync` 手動実行 | 上と同じだが対話的（成功/失敗が見える） |
| 衝突発生 | 自動同期は中断＆macOS通知 → 手動解決が必要 |
| ネットワーク不通 | 自動同期は静かに失敗、次回再試行 |

---

## 🆘 最終手段：全部やり直す

何かが致命的に壊れた場合の復旧手順。

```bash
# 1. シンボリックリンクを全削除
rm -f ~/.claude/{skills,memory,hooks,CLAUDE.md,settings.json}
rm -f ~/Library/Application\ Support/Claude/claude_desktop_config.json

# 2. バックアップから戻す
ls ~/.claude-config-backups/    # ← 最新のバックアップ日時を確認
cp -R ~/.claude-config-backups/<最新の日時>/* ~/.claude/

# 3. リポジトリから再構築したい場合
cd ~/git/claude-config
git pull
./scripts/install.sh
```

---

このファイルはリポジトリで両PCに同期されている。新しい運用ルールが見つかったらここに追記して `claude-sync`。
