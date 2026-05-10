# Claude Config Sync

> 複数のMac間で **Claude Code** と **Claude Desktop / Cowork** の設定・スキル・memoryを Git経由で双方向同期するためのテンプレート

> **⚠️ v1.0 利用者へのお知らせ (2026-05)**: v1.0 では Claude Code の **project-level auto-memory** (`~/.claude/projects/-Users-<USER>/memory/`) が同期対象から漏れていました。`memory-save` で明示保存したものは同期されますが、Claude Code が自動で書く auto-memory は同期されません。**修復するには `./scripts/setup-memory.sh` を実行してください。** 詳細は [Release v1.1](https://github.com/zhenmtapp/claude-config-sync/releases) と [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) を参照。

## なぜこれが必要か

複数のMacで Claude を使っていると、

- 片方で作ったスキルがもう一方では使えない
- `memory-save` で貯めた学習が共有されない
- `CLAUDE.md` の編集を都度コピペする必要がある
- `settings.json` の permission や hooks 設定がバラバラ

このテンプレートを使うと、**30分ごとに自動でcommit/pull/push**され、両PCで完全に同じ設定・skill・memoryが使える状態になります。

```
   Mac A                          GitHub                          Mac B
┌─────────────┐               ┌──────────────┐               ┌─────────────┐
│ ~/.claude/  │ symlink to    │              │ symlink to    │ ~/.claude/  │
│  ├─skills/  │  ~/git/...    │ claude-config│  ~/git/...    │  ├─skills/  │
│  ├─memory/  │ ←──────────→  │  (private)   │ ←──────────→  │  ├─memory/  │
│  └─...      │               │              │               │  └─...      │
└─────────────┘               └──────────────┘               └─────────────┘
       ↑                              ↑                              ↑
   launchd 30min auto-sync       (single source of truth)      launchd 30min auto-sync
```

## できること

- ✅ Claude Code (`~/.claude/`) の設定・skills・memory・hooks・CLAUDE.md を双方向同期
- ✅ Claude Desktop / Cowork (`~/Library/Application Support/Claude/claude_desktop_config.json`) の MCP設定も同期
- ✅ launchd で30分ごとに自動同期 (バックグラウンド)
- ✅ `claude-sync` 1コマンドで即時同期
- ✅ `cclaude` 1コマンドでステータス確認
- ✅ Claude Code のスキルとして「同期確認して」「/sync-check」で呼び出し可能
- ✅ マシン固有の設定は `~/.claude/settings.local.json` で分離

## できないこと

- ❌ リアルタイム同期 (30分間隔 or 手動)
- ❌ 認証情報・トークン・セッション履歴の同期 (意図的に除外)
- ❌ プラグイン本体の同期 (各PCで個別インストール必要、`enabledPlugins` リストは同期される)
- ❌ Windows / Linux 対応 (macOS の launchd 前提)

## 必要なもの

- macOS 11以降 (推奨13以降)
- 同期したい2台以上のMac (ユーザー名は同じでなくてもOK)
- Git
- **GitHub のプライベートリポジトリ** (重要: 公開リポジトリは絶対に使わない)

---

## クイックスタート

### 1. このテンプレートから自分用リポジトリを作る

GitHub の **"Use this template"** ボタンを押して、**Private** で新しいリポジトリを作成（リポジトリ名は何でも良い、例: `my-claude-config`）。

ローカルにcloneして、メインPCの `~/git/claude-config` に置きます：

```bash
mkdir -p ~/git
cd ~/git
git clone git@github.com:YOUR_USER/YOUR_REPO.git claude-config
cd claude-config
chmod +x scripts/*.sh skills/sync-check/scripts/*.sh
```

### 2. 1台目（マスター）でセットアップ

既存の Claude 設定をリポジトリに取り込みます：

```bash
cd ~/git/claude-config

# 既存設定をリポジトリにコピー (skills, memory, hooks, CLAUDE.md, settings.json, claude_desktop_config.json)
./scripts/init-from-existing.sh

# 中身を確認 (★重要★ 認証情報が混入していないか目視チェック)
git add -A
git status
cat code/settings.json | grep -iE "(token|key|password|secret)" || echo "✅ 機密情報なし"
```

問題なければ初回commit & push：

```bash
git commit -m "initial: claude config snapshot"
git push origin main
```

実体ファイルをシンボリックリンクに置き換え：

```bash
./scripts/install.sh
# → 既存の ~/.claude/* は ~/.claude-config-backups/<日時>/ に自動退避される
```

### 3. 自動同期を有効化（launchd）

```bash
# plist テンプレートからユーザー固有のplistを生成
mkdir -p ~/Library/LaunchAgents
cp templates/com.user.claude-config-sync.plist.template \
   ~/Library/LaunchAgents/com.user.claude-config-sync.plist

# launchd ジョブをロード (30分ごとに自動同期開始)
launchctl unload ~/Library/LaunchAgents/com.user.claude-config-sync.plist 2>/dev/null
launchctl load ~/Library/LaunchAgents/com.user.claude-config-sync.plist

# 確認
launchctl list | grep claude-config
# → "- 0 com.user.claude-config-sync" が出ればOK
```

### 4. `.zshrc` にエイリアスを追加

```bash
cat templates/zshrc-snippet.sh >> ~/.zshrc
source ~/.zshrc

# 動作確認
cclaude
```

### 5. 2台目のMacでセットアップ

```bash
# リポジトリをclone
mkdir -p ~/git
cd ~/git
git clone git@github.com:YOUR_USER/YOUR_REPO.git claude-config
cd claude-config
chmod +x scripts/*.sh skills/sync-check/scripts/*.sh

# シンボリックリンクを張る (既存の ~/.claude は自動バックアップ)
./scripts/install.sh

# 自動同期 (3) と .zshrc 設定 (4) は1台目と同じ手順で実行
```

---

## 日常運用

| やりたいこと | コマンド |
|---|---|
| 何もしない | (30分ごとに自動同期される) |
| 即時同期したい | `claude-sync` |
| 同期状態を確認 | `cclaude` |
| Claudeに状態確認を依頼 | 「同期確認して」「/sync-check」 |
| 困ったときの参照 | `docs/CHEATSHEET.md` |

---

## マシン固有の設定（同期したくない設定）

特定のMacでしか使わない permission やパスは、**`~/.claude/settings.local.json`** に書きます。これはリポジトリに含まれず、そのMacだけで有効になります。

例：

```json
{
  "permissions": {
    "allow": [
      "Read(/Users/your-user/Documents/local-only-project/**)"
    ],
    "additionalDirectories": [
      "/Users/your-user/Documents/local-only-project"
    ]
  }
}
```

---

## ドキュメント

- 📋 [docs/CHEATSHEET.md](docs/CHEATSHEET.md) - 日常運用チートシート
- 🔒 [docs/SECURITY.md](docs/SECURITY.md) - セキュリティチェックリスト（**push前に必ず確認**）
- 🛠 [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) - トラブル対処集

---

## カスタマイズ

### 同期対象を変更する

`scripts/install.sh` と `scripts/init-from-existing.sh` の上部にある `CLI_ITEMS` / `DESKTOP_ITEMS` 配列を編集。

```bash
CLI_ITEMS=(
  "skills"
  "memory"
  "CLAUDE.md"
  "settings.json"
  "hooks"
  # ここに追加したい項目を書く (~/.claude/<name> の name 部分)
)
```

### 自動同期の間隔を変更する

`~/Library/LaunchAgents/com.user.claude-config-sync.plist` を編集して、`<integer>1800</integer>`（秒単位）を変更。例: `900` で15分、`3600` で1時間。

```bash
# 変更後は再ロード
launchctl unload ~/Library/LaunchAgents/com.user.claude-config-sync.plist
launchctl load ~/Library/LaunchAgents/com.user.claude-config-sync.plist
```

### リポジトリの場所を変更する

デフォルトは `~/git/claude-config`。変更したい場合は `templates/zshrc-snippet.sh` の `CLAUDE_CONFIG_REPO` 環境変数と、各 plist 内のパスを修正してください。

---

## アンインストール

```bash
# 1. launchd ジョブを停止 & 削除
launchctl unload ~/Library/LaunchAgents/com.user.claude-config-sync.plist
rm ~/Library/LaunchAgents/com.user.claude-config-sync.plist

# 2. シンボリックリンクを実体に戻す（バックアップから復元）
ls ~/.claude-config-backups/   # ← 最新の日時を確認
rm ~/.claude/{skills,memory,hooks,CLAUDE.md,settings.json}
cp -R ~/.claude-config-backups/<最新の日時>/* ~/.claude/

# 3. .zshrc から CLAUDE_CONFIG_REPO 関連を削除（手動）

# 4. リポジトリを削除
rm -rf ~/git/claude-config
```

---

## License

MIT - [LICENSE](LICENSE) を参照
