<div align="center">

<img src="logo-header.svg" alt="vex header logo">

シンタックスハイライトとインライン編集を備えた、モダンなAST対応diffツール。Zigで構築。

[主要機能](#主要機能) • [使い方](#使い方) • [インストール](#インストール) • [カスタマイズ](#カスタマイズ) • [FAQ](#faq)

[English](../README.md) | [日本語](README-ja.md)

[![Build Status](https://github.com/ydah/vex/workflows/CI/badge.svg)](https://github.com/ydah/vex/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](../LICENSE)
[![GitHub release](https://img.shields.io/github/v/release/ydah/vex)](https://github.com/ydah/vex/releases)

</div>

vexはコードの構造を理解します。意味のない行単位の変更ではなく、関数の移動、変数のリネーム、式の変更といったセマンティックな差分をハイライト—すべて美しいTUIとインライン編集で。

---

## 主要機能

### AST対応差分表示

テキスト変更ではなく、セマンティックな差分を理解。

<!-- ![AST対応差分の例](screenshots/ast-diff.png) -->

### Side-by-Side表示

美しいサイドバイサイドレイアウトでファイルを比較。対応する行が水平に揃います。

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

### インライン編集

差分表示画面から直接ファイルを編集。どちらかの変更を採用、両方をマージ、または手動で編集—すべてvexを離れることなく実行可能。

### 超高速

ZigとSIMD最適化により、大規模ファイル（1MB以上）でも1秒以内に処理。

| 操作 | 目標時間 |
| --- | --- |
| 起動 | < 50ms |
| 小ファイル差分 (< 1KB) | < 10ms |
| 中ファイル差分 (1-100KB) | < 100ms |
| 大ファイル差分 (1MB+) | < 1s |

### テーマ

組み込みテーマ: `tokyo-night`（デフォルト）、`github-dark`、`monokai`

---

## 使い方

### 基本コマンド

```bash
# 2つのファイルを比較
vex old_file.txt new_file.txt

# Side-by-Sideモード（デフォルト）
vex -s old.zig new.zig

# Unified diffモード
vex -u old.rs new.rs

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

### キーバインド

| キー | アクション |
| --- | --- |
| `j` / `↓` | 下にスクロール |
| `k` / `↑` | 上にスクロール |
| `n` / `N` | 次 / 前のHunk |
| `Tab` | Side-by-Side / Unified 切り替え |
| `a` | 左側を採用 |
| `d` | 右側を採用 |
| `e` | 手動編集モード |
| `u` | 元に戻す |
| `q` | 終了 |

---

## インストール

### ソースからビルド (Zig 0.13.0+)

```bash
git clone https://github.com/ydah/vex.git
cd vex
zig build -Doptimize=ReleaseFast
sudo cp zig-out/bin/vex /usr/local/bin/
```

### プラットフォームサポート

| プラットフォーム | 状態 |
| --- | --- |
| Linux (x86_64) | ✅ サポート |
| Linux (aarch64) | ✅ サポート |
| macOS (x86_64) | ✅ サポート |
| macOS (Apple Silicon) | ✅ サポート |
| Windows | 🚧 予定 |

---

## 連携

### Git

```bash
# difftoolとして設定
git config --global diff.tool vex
git config --global difftool.vex.cmd 'vex "$LOCAL" "$REMOTE"'

# gitで使用
git difftool HEAD~3
```

---

## カスタマイズ

### テーマ

```bash
export VEX_THEME=github-dark
vex file1.txt file2.txt
```

### 環境変数

| 変数 | 説明 | デフォルト |
| --- | --- | --- |
| `VEX_THEME` | カラーテーマ | `tokyo-night` |
| `VEX_PAGER` | ページャープログラム | なし |
| `NO_COLOR` | 設定時にカラーを無効化 | - |

---

## FAQ

### TUIの表示が崩れる

ターミナルがtrue colorをサポートしているか確認：

```bash
echo $COLORTERM
```

### カラーを無効化するには？

```bash
vex --no-color file1.txt file2.txt
# または
NO_COLOR=1 vex file1.txt file2.txt
```

---

## プロジェクトの目標

- 高速: 起動 < 50ms、小規模差分 < 10ms
- セマンティック: 意味のある変更のためのAST対応差分
- ビジュアルファースト: ライブ編集機能付きの美しいTUI
- ゼロコンフィグ: すぐに使える

---

## 開発

```bash
# デバッグビルド
zig build

# リリースビルド
zig build -Doptimize=ReleaseFast

# テスト
zig build test

# 引数付きで実行
zig build run -- file1.zig file2.zig
```

コントリビューション歓迎。ワークフローとスタイルについては `CONTRIBUTING.md` を参照。

---

## ライセンス

MIT。詳細は `LICENSE` を参照。

## クレジット

- [delta](https://github.com/dandavison/delta)と[difftastic](https://github.com/Wilfred/difftastic)にインスピレーションを受けました
- 言語は[Zig](https://ziglang.org/)
- Myers差分アルゴリズムはEugene W. Myersによる"An O(ND) Difference Algorithm"に基づいています
