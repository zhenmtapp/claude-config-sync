# 使い方別セットアップガイド

「自分はどう設定すればいい?」「既存セットアップをどう直せばいい?」が分からない人向け。
**3秒チャート → 詳細ケース別 → 既存ユーザー向け移行手順** の順で読んでください。

---

## 🎯 3秒チャート（あなたのケースを特定）

```
   Q1: Mac は何台ありますか?
        │
        ├─ 1台 ────────────────────────────→ Case 0: 同期不要
        │
        └─ 複数台
            │
            Q2: 同じプロジェクトを複数Macで触りますか?
                │
                ├─ Yes（同じプロジェクト） ────→ Case 1: フル同期 ⭐推奨
                │
                ├─ 一部のプロジェクトだけ ──→ Case 2: 選択的同期
                │
                └─ 完全に別プロジェクト ──→ Case 3: ライト同期
```

```
   Q3: チームで共有? それとも個人?
        │
        ├─ 個人のみ ────────────────────→ 上の Case 0-3 のいずれか
        │
        └─ チームで共有
            │
            Q4: 全員で同じ設定を使う? 各自カスタム?
                │
                ├─ 統一 ────────────────→ Case 4: チーム共有
                │
                └─ 各自カスタム ──────→ Case 5: テンプレ配布のみ
```

---

## 📋 ケース別詳細

### Case 0: 単一Mac、同期不要

**状況**: Macが1台しかない / 同期する必要がない

**推奨セットアップ**: このテンプレートは**そもそも不要**。

ただし「いつか2台目を買うかも」という保険として、軽量に始めることは可能：

```bash
git clone <your-repo>.git ~/git/claude-config
cd ~/git/claude-config
chmod +x scripts/*.sh
./scripts/init-from-existing.sh
git push
./scripts/install.sh
# launchd は設定しない（同期相手が無いため）
```

→ 結果: バックアップとしてリポジトリに設定が残る。2台目購入時に install.sh で即座に同期開始可能。

---

### Case 1: 複数Mac × 同じプロジェクト ⭐ 最推奨

**状況**: MBPとMac Studioで同じコードベース・同じ用途で開発する

**例**:
- 自宅 (Mac Studio) と外出先 (MBP) で同じプロジェクトを進める
- デスクトップで重い処理、ノートPCで設計や打ち合わせ用

**推奨セットアップ**: **フル同期**（user-level + project-level memory 両方）

```bash
# 1. リポジトリ準備
git clone <your-repo>.git ~/git/claude-config
cd ~/git/claude-config
chmod +x scripts/*.sh

# 2. 既存設定を取り込み
./scripts/init-from-existing.sh
git add -A && git status   # 機密情報チェック
git commit -m "initial: claude config snapshot"
git push

# 3. シンボリックリンク作成
./scripts/install.sh

# 4. ★project-level memory も同期★
./scripts/setup-memory.sh
# → A を選択

# 5. 自動同期 launchd
mkdir -p ~/Library/LaunchAgents
cp templates/com.user.claude-config-sync.plist.template \
   ~/Library/LaunchAgents/com.user.claude-config-sync.plist
launchctl load ~/Library/LaunchAgents/com.user.claude-config-sync.plist

# 6. .zshrc
cat templates/zshrc-snippet.sh >> ~/.zshrc
source ~/.zshrc
```

**両Macで同じ手順を実行**（2台目では `git clone` のみ、`init-from-existing.sh` は不要）。

**結果**: skill / memory / hooks / settings / claude_desktop_config / **auto-memory** 全て両Macで完全同期。Claude Codeに「以前これやったよね?」と聞いても両方のMacで通じる。

---

### Case 2: 複数Mac × 一部のプロジェクトだけ共通

**状況**: 大半は別プロジェクトだが、一部は両Macで触る

**例**:
- MBPは仕事専用、Mac Studioは個人開発専用、ただし副業プロジェクトだけ両方で触る

**推奨セットアップ**: **選択的同期**

基本セットアップは Case 1 と同じだが、**`setup-memory.sh` で B を選択** して project-level memory はローカル管理にする。共有したいプロジェクトは別途、プロジェクト直下の `.claude/CLAUDE.md` に記憶を蓄積し、git でそのプロジェクト自体を共有する。

```bash
# 1-3. Case 1 と同じ
# ...

# 4. project-level memory はローカル管理（B選択）
./scripts/setup-memory.sh
# → B を選択

# 5-6. Case 1 と同じ
```

**結果**: skill / memory-save / settings は同期、Claude Codeのauto-memoryは各Macローカル。混ざらない。

---

### Case 3: 複数Mac × 完全に別プロジェクト

**状況**: 各Macで全く別のことをする

**例**:
- 自宅 (Mac Studio) はゲーム・趣味、職場 (MBP) は仕事

**推奨セットアップ**: **ライト同期**（user-level のみ）

```bash
# 1-3. Case 1 と同じ
# ...

# 4. project-level memory は同期しない (B選択)
./scripts/setup-memory.sh
# → B を選択

# 5-6. Case 1 と同じ
```

**結果**: 汎用的な学び（memory-save 等）と skill は両Macで共有、プロジェクト個別の記憶は各Mac独立。

---

### Case 4: チームで共有・統一設定

**状況**: チームメンバー全員が同じ設定を使いたい

**例**:
- 開発チームで「全員このskill使おう」「このCLAUDE.mdが標準」

**推奨セットアップ**: **テンプレートをfork → チーム用リポジトリを作成 → 各自clone**

```bash
# チームリーダーが1回:
# 1. claude-config-sync テンプレを fork
#    https://github.com/<original>/claude-config-sync → fork
# 2. fork先 (例: my-team-org/claude-config) を整備
#    - チーム共通 skill を追加
#    - チーム標準 CLAUDE.md を作成
#    - settings.json を整える
# 3. fork先を全員に共有

# 各メンバー:
git clone git@github.com:<team-org>/claude-config.git ~/git/claude-config
./scripts/install.sh
./scripts/setup-memory.sh   # 各自の事情で A/B/C 選択
```

**注意**:
- メンバーが個別に skill 追加した場合、チーム reposに push すると全員に配信される（意図次第で吉凶）
- 各自の memory は混ざるので、個人memory用に**別 fork** を作るほうが安全な場合も

---

### Case 5: テンプレ配布のみ・各自カスタム

**状況**: テンプレは紹介するが、各自が自分で運用する

**例**:
- 社内に「こういうセットアップどう?」と紹介、各自がfork

**推奨セットアップ**: **テンプレリポジトリを公開 / 限定共有**

```bash
# 配布側: claude-config-sync (template repo) を公開
# Settings → Template repository ☑

# 受け取る側: "Use this template" で自分のリポを作成
# → 完全に独立した自分用リポジトリができる
# → 自分で setup-memory.sh の A/B/C を判断
```

各自の memory も skill も**完全に独立**。テンプレを共有するだけで、データは混ざらない。

---

## 🔧 既存ユーザー向け：移行・修復手順

### あなたの状況を診断

```bash
# 1. 同期対象の現状
ls -la ~/.claude/{skills,memory,hooks,CLAUDE.md,settings.json} 2>/dev/null
# → symlink になっていれば既に同期セットアップ済み

# 2. project-level auto-memory の状態
ls ~/.claude/projects/-Users-$(whoami)/memory/ 2>/dev/null | wc -l
# → 0以外の数字 = 未同期ファイルあり (v1.0バグの影響)

# 3. launchd 稼働確認
launchctl list | grep claude-config
# → 出力あり = 自動同期中 / なし = 手動運用
```

### 既存ユーザー: ケース別の対処

#### A. 「v1.0 で運用していて、project-level memory が未同期」

→ **Case 1 を選んだなら setup-memory.sh A 実行が必須**

```bash
cd ~/git/claude-config
git pull   # v1.1 取り込み
chmod +x scripts/setup-memory.sh
./scripts/setup-memory.sh
# → A 選択（既存ファイルは退避→claude-config に取り込み→symlink）
```

両Macで実行してください。

#### B. 「Case 3 で運用したい (project-level は別管理)」

→ **setup-memory.sh B でローカル管理を明示**

```bash
./scripts/setup-memory.sh
# → B 選択
```

→ 何も変わらないが、「意図的に同期しない」が確定する。今後 `sync-check` スキルが「未同期だよ」と警告しなくなる（注: 現バージョンは警告しないが将来追加されるかも）。

#### C. 「launchd 自動同期を入れていない（手動運用）」

→ **30分自動同期を入れる**

```bash
mkdir -p ~/Library/LaunchAgents
cp ~/git/claude-config/templates/com.user.claude-config-sync.plist.template \
   ~/Library/LaunchAgents/com.user.claude-config-sync.plist
launchctl load ~/Library/LaunchAgents/com.user.claude-config-sync.plist
```

#### D. 「シンボリックリンクが壊れた / 設定が反映されない」

→ **install.sh で再構築**

```bash
cd ~/git/claude-config
./scripts/install.sh
# → 既存の ~/.claude/* は ~/.claude-config-backups/ に自動退避
```

#### E. 「使い方が変わった (Case 1 → Case 3 とか)」

→ **setup-memory.sh で設定変更 + 必要なら手動で symlink 解除**

```bash
# Case 1 → Case 3 (project-level 同期を解除する場合)
rm ~/.claude/projects/-Users-$(whoami)/memory   # symlink削除
mkdir ~/.claude/projects/-Users-$(whoami)/memory   # ローカル空dir作成
# 必要なら過去のファイルを restore
cp ~/git/claude-config/code/memory/*.md ~/.claude/projects/-Users-$(whoami)/memory/
```

注意: claude-config 側のファイルはMac Studioにも残るので、後で削除するなら両Mac同期した上で `git rm` する。

---

## 🆘 「分からない、とりあえず安全に」

迷ったら：

1. **まず Case 0 で始める**（同期しない / バックアップだけ）
2. 1-2週間運用してみる
3. 「やっぱり共有したい」と思ったら Case 1〜3 にステップアップ

setup-memory.sh はいつでも再実行できるので、**A → B → A** のような変更も自由です。バックアップが取られるのでデータロスもしません。

---

## ❓ FAQ

**Q: setup-memory.sh で A を選んだら他Macの auto-memory も全部こっちに来ますか?**
A: はい。両Macで A を実行すると、両者の auto-memory が同じ `claude-config/code/memory/` プールにマージされます。

**Q: 同名ファイルがあったらどうなる?**
A: setup-memory.sh の A は `cp -n`（既存優先）でコピーするので、claude-config 側に既にあるファイルは上書きされません。Mac Studio側のファイルが優先される動きになります。

**Q: チームメンバーに自分のmemoryが見られるのが嫌**
A: Case 5（各自fork）にしてください。テンプレだけ共有、データは個人リポジトリで完全分離。

**Q: 後で「やっぱり同期辞めたい」となったら?**
A: アンインストール手順は README.md 末尾に記載。symlink を実体に戻せば、リポジトリを削除しても残ります。
