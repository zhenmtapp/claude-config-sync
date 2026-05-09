# Security Notes

このリポジトリは**個人の設定・スキル・memory** を含むため、必ず**プライベートリポジトリで運用**してください。

## 🔒 大原則

1. **絶対に Public リポジトリにしない**
2. **初回push前に必ず `git status` で内容を目視確認**
3. **APIキー・トークン・パスワードが含まれていないか確認**
4. **`.gitignore` を編集する場合は除外パターンを削らない**

---

## ✅ 自動的に除外されるもの（`.gitignore` 設定済み）

| 種別 | 例 |
|---|---|
| 認証情報 | `.credentials.json`, `*.token`, `*.key`, `*.pem`, `.env*` |
| Claude Code セッション | `code/sessions/`, `code/projects/`, `code/local-agent-mode-sessions/` |
| Claude Desktop ローカル状態 | `desktop/Cache/`, `desktop/IndexedDB/`, `desktop/Local Storage/`, `desktop/Cookies*` |
| キャッシュ・ログ | `*.log`, `cache/`, `.auto-sync.log` |

---

## ⚠️ 初回 push 前のチェックリスト

```bash
cd ~/git/claude-config

# 1. 認証系キーワードの混入チェック
grep -rE "(api[_-]?key|token|password|secret|bearer)" \
  --include="*.json" --include="*.md" --include="*.sh" \
  code/ desktop/ 2>/dev/null

# 2. settings.json の中身を目視
cat code/settings.json

# 3. claude_desktop_config.json (MCP設定) の中身を目視
cat desktop/claude_desktop_config.json

# 4. ステージされたファイル一覧を確認
git status
```

特に注意：

- `code/settings.json` の `enabledPlugins` は安全（プラグイン名のみ）
- `code/settings.json` の `hooks` でローカルパスを参照していてもOK（パス情報のみ）
- `desktop/claude_desktop_config.json` の MCP サーバー設定で**APIキーが直書き**されている場合は要対処
  - 例: `"env": {"OPENAI_API_KEY": "sk-..."}` → これは絶対NG
  - 解決策: `.gitignore` に `desktop/claude_desktop_config.json` を追加するか、APIキー部分を環境変数化

---

## 🌐 GitHub プライベートリポジトリの確認方法

リポジトリページにアクセスして、

- リポジトリ名の右側に 🔒 アイコンが付いている
- "Private" バッジが表示されている

を必ず確認してください。

公開状態は **Settings → General → Danger Zone → Change repository visibility** で変更可能です。

---

## 🔐 万一の漏洩対応

もし誤ってトークンやAPIキーをpushしてしまった場合：

1. **即座にキー/トークンを失効・再発行**（Git履歴に残るため、ファイルから削除しただけではダメ）
   - GitHub PAT: <https://github.com/settings/tokens>
   - OpenAI/Anthropic等: 各サービスのAPIキー管理画面
2. リポジトリを**一時的に削除 or プライベート化**
3. Git履歴から該当ファイルを完全削除（`git filter-branch` や `BFG Repo-Cleaner`）

---

## 📌 推奨：マシン固有の機密設定は `settings.local.json` へ

特定のマシンだけで使う permission・パス・キーは、`~/.claude/settings.local.json` に書いてください。これは `.gitignore` で除外されており、リポジトリには含まれません。

```json
{
  "permissions": {
    "allow": [
      "Read(/Users/your-user/secret-project/**)"
    ]
  }
}
```
