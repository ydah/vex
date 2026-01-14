<p align="center">
  <img src="logo-header.svg" alt="vex">
</p>

<p align="center">
  <a href="https://github.com/ydah/vex/actions"><img src="https://github.com/ydah/vex/workflows/CI/badge.svg" alt="Build Status"></a>
  <a href="https://github.com/ydah/vex/releases"><img src="https://img.shields.io/github/v/release/ydah/vex?color=319e8c" alt="Version"></a>
  <a href="../LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License"></a>
</p>

<p align="center">
  シンタックスハイライトとインライン編集を備えた、モダンな<b>AST対応diffツール</b>。<br>
  Zig言語で構築され、最高のパフォーマンスを実現。
</p>

<p align="center">
  <a href="#主要機能">主要機能</a> •
  <a href="#使い方">使い方</a> •
  <a href="#インストール">インストール</a> •
  <a href="#カスタマイズ">カスタマイズ</a> •
  <a href="#キーバインド">キーバインド</a>
</p>

<p align="center">
  [<a href="../README.md">English</a>]
  [日本語]
</p>

---

## 主要機能

### AST対応差分表示

`vex`はコードの構造を理解します。意味のない行単位の変更ではなく、関数の移動、変数のリネーム、式の変更といったセマンティックな差分をハイライトします。

<!-- ![AST対応差分の例](screenshots/ast-diff.png) -->

### Side-by-Side表示

美しいサイドバイサイドレイアウトでファイルを比較。対応する行が水平に揃うため、一目で違いを把握できます。

```
old.zig                           │ new.zig
──────────────────────────────────┼──────────────────────────────────
@@ -1,3                           │ +1,4 @@
   1 const std = @import("std");  │    1 const std = @import("std");
   2-const x = 10;                │
                                  │    2+const x = 20;
                                  │    3+const y = 30;
   3 pub fn main() void {}        │    4 pub fn main() void {}
```

### Unified Diff表示

カラフルな出力のクラシックなunified diff形式：

```diff
--- old.zig
+++ new.zig
@@ -1,3 +1,4 @@
 const std = @import("std");
-const x = 10;
+const x = 20;
+const y = 30;
 pub fn main() void {}
```

### シンタックスハイライト

Tree-sitterを活用し、40以上のプログラミング言語のシンタックスハイライトに対応（近日対応予定）。差分は情報的であるだけでなく、美しく表示されます。

### インライン編集

差分表示画面から直接ファイルを編集。どちらかの変更を採用、両方をマージ、または手動で編集—すべてvexを離れることなく実行できます。

| キー | アクション |
|------|-----------|
| `a` | 左側（旧）を採用 |
| `d` | 右側（新）を採用 |
| `e` | 手動編集モード |

### Git連携

`git diff`の出力を直接vexにパイプして、リッチな可視化を実現：

```bash
git diff | vex -
git diff HEAD~3 | vex --ast -
```

### 超高速

ZigとSIMD最適化により、大規模ファイル（1MB以上）でもAST解析込みで1秒以内に処理。

| 操作 | 目標時間 |
|------|---------|
| 起動 | < 50ms |
| 小ファイル差分 (< 1KB) | < 10ms |
| 中ファイル差分 (1-100KB) | < 100ms |
| 大ファイル差分 (1MB+) | < 1s |

---

## 使い方

### 基本的な使い方

```bash
# 2つのファイルを比較
vex old_file.txt new_file.txt

# Side-by-Sideモード（デフォルト）
vex -s old.zig new.zig

# Unified diffモード
vex -u old.rs new.rs
```

### オプション付き

```bash
# カラー無効化（他ツールへのパイプ用）
vex --no-color file1.txt file2.txt

# コンテキスト行数をカスタマイズ（デフォルト: 3）
vex -c 5 before.js after.js

# AST対応モードを有効化
vex --ast old.py new.py
```

### 標準入力からの読み込み

```bash
# '-' で標準入力から読み込み
cat file.txt | vex - other.txt

# git diffをパイプ
git diff | vex -
git show HEAD | vex -
```

### Git連携

vexをデフォルトのdiffツールとして設定：

```bash
# difftoolとして設定
git config --global diff.tool vex
git config --global difftool.vex.cmd 'vex "$LOCAL" "$REMOTE"'

# gitで使用
git difftool HEAD~3
```

---

## インストール

### ソースからビルド（推奨）

Zig 0.13.0 以降が必要です。

```bash
git clone https://github.com/ydah/vex.git
cd vex
zig build -Doptimize=ReleaseFast
```

バイナリは `./zig-out/bin/vex` に生成されます。

```bash
# PATHに追加
sudo cp ./zig-out/bin/vex /usr/local/bin/

# またはローカルインストール
mkdir -p ~/.local/bin
cp ./zig-out/bin/vex ~/.local/bin/
```

### プラットフォームサポート

| プラットフォーム | 状態 |
|-----------------|------|
| Linux (x86_64) | ✅ サポート |
| Linux (aarch64) | ✅ サポート |
| macOS (x86_64) | ✅ サポート |
| macOS (Apple Silicon) | ✅ サポート |
| Windows | 🚧 予定 |

---

## コマンドラインオプション

```
使い方:
    vex [オプション] <file1> <file2>

引数:
    <file1>    比較する最初のファイル（'-' で標準入力）
    <file2>    比較する2番目のファイル

オプション:
    -s, --side-by-side    Side-by-Side表示モード（デフォルト）
    -u, --unified         Unified diff形式
    --ast                 AST対応モードを有効化
    --no-color            カラー出力を無効化
    -c, --context <N>     コンテキスト行数（デフォルト: 3）
    -h, --help            ヘルプメッセージを表示
    -v, --version         バージョン情報を表示
```

---

## キーバインド

### ナビゲーション

| キー | アクション |
|------|-----------|
| `j` / `↓` | 下にスクロール |
| `k` / `↑` | 上にスクロール |
| `Space` / `Page Down` | ページダウン |
| `b` / `Page Up` | ページアップ |
| `g` | 先頭行へ移動 |
| `G` | 最終行へ移動 |
| `n` | 次のHunkへジャンプ |
| `N` | 前のHunkへジャンプ |

### 表示モード

| キー | アクション |
|------|-----------|
| `Tab` | Side-by-Side / Unified 切り替え |
| `w` | 単語差分切り替え |
| `l` | 行番号表示切り替え |

### 編集

| キー | アクション |
|------|-----------|
| `a` | 左側（旧）を採用 |
| `d` | 右側（新）を採用 |
| `e` | 手動編集モードに入る |
| `u` | 元に戻す (Undo) |
| `Ctrl+r` | やり直し (Redo) |

### 一般

| キー | アクション |
|------|-----------|
| `/` | 検索 |
| `?` | ヘルプ表示 |
| `q` | 終了 |

---

## カスタマイズ

### カラーテーマ

vexには複数の組み込みテーマがあります：

- Tokyo Night（デフォルト）- モダンなダークテーマ
- GitHub Dark - GitHub風のダークテーマ
- Monokai - クラシックなMonokaiカラー

```bash
# 環境変数でテーマを設定
export VEX_THEME=github-dark
vex file1.txt file2.txt
```

### 環境変数

| 変数 | 説明 |
|------|------|
| `VEX_THEME` | デフォルトのカラーテーマ |
| `VEX_PAGER` | ページャープログラム（デフォルト: なし） |
| `NO_COLOR` | 設定時にカラーを無効化 |

---

### vexを使うべき場面

- テキスト変更だけでなくセマンティックな差分を理解したい
- 差分を確認しながら編集とマージをしたい
- 大規模コードベースで作業しており、速度が必要
- コードレビュー用の美しいTUIが欲しい

### 他ツールを使うべき場面

- diff: シンプルで汎用的なツールが必要な場合
- delta: TUIなしでgit diff出力を強化したい場合
- difftastic: 編集機能なしでAST対応diffのみ必要な場合

---

## 開発

```bash
# リポジトリをクローン
git clone https://github.com/ydah/vex.git
cd vex

# ビルド（デバッグ）
zig build

# ビルド（リリース）
zig build -Doptimize=ReleaseFast

# テスト実行
zig build test

# 引数付きで実行
zig build run -- file1.zig file2.zig

# コードフォーマット
zig fmt src/
```

### プロジェクト構成

```
vex/
├── src/
│   ├── main.zig           # エントリーポイント
│   ├── cli.zig            # CLI引数解析
│   ├── core/
│   │   ├── diff.zig       # Myers差分アルゴリズム
│   │   └── hunks.zig      # Hunk生成
│   ├── output/
│   │   ├── unified.zig    # Unified diff出力
│   │   └── side_by_side.zig
│   ├── ui/
│   │   ├── tui.zig        # TUIメインループ
│   │   ├── terminal.zig   # ターミナル制御
│   │   ├── renderer.zig   # 画面レンダリング
│   │   └── colors.zig     # カラーテーマ
│   ├── editor/
│   │   ├── buffer.zig     # テキストバッファ
│   │   ├── operations.zig # 編集操作
│   │   └── undo.zig       # Undo/Redoスタック
│   └── utils/
│       ├── io.zig         # ファイルI/O
│       └── simd.zig       # SIMD最適化
└── build.zig
```

---

## コントリビュート

コントリビューションを歓迎します！お気軽にPull Requestをお送りください。

### 協力が必要な領域

- より多くの言語のサポート追加（Tree-sitter文法）
- ASTマッチングアルゴリズムの改善
- パフォーマンス最適化
- ドキュメントと翻訳
- Windowsサポート

---

## ライセンス

vexはMITライセンスの下で公開されています。詳細は[LICENSE](../LICENSE)を参照してください。

---

## 謝辞

- [delta](https://github.com/dandavison/delta)と[difftastic](https://github.com/Wilfred/difftastic)にインスピレーションを受けました
- [Zig](https://ziglang.org/)で構築
- Myers差分アルゴリズムはEugene W. Myersによる"An O(ND) Difference Algorithm"に基づいています
