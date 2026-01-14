<div align="center">

<img src="doc/logo-header.svg" alt="vex header logo">

A modern AST-aware diff tool with syntax highlighting and inline editing, built in Zig.

[Key Features](#key-features) • [Usage](#usage) • [Install](#install) • [Customize](#customize) • [FAQ](#faq)

[English](README.md) | [日本語](doc/README-ja.md)

[![Build Status](https://github.com/ydah/vex/workflows/CI/badge.svg)](https://github.com/ydah/vex/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![GitHub release](https://img.shields.io/github/v/release/ydah/vex)](https://github.com/ydah/vex/releases)

</div>

vex understands the structure of your code. Instead of showing meaningless line-by-line changes, it highlights semantic differences like moved functions, renamed variables, and modified expressions—all in a beautiful TUI with inline editing.

---

## Key Features

### AST-Aware Diff

Understand semantic differences, not just text changes.

<!-- ![AST-aware diff example](doc/screenshots/ast-diff.png) -->

### Side-by-Side View

Compare files with a beautiful side-by-side layout. Corresponding lines are aligned horizontally.

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

### Unified Diff View

Classic unified diff format with colorful output:

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

### Inline Editing

Edit files directly from the diff view. Accept changes from either side, merge both, or make manual edits—all without leaving vex.

### Blazing Fast

Written in Zig with SIMD optimizations, vex handles large files (1MB+) in under a second.

| Operation | Target |
| --- | --- |
| Startup | < 50ms |
| Small file diff (< 1KB) | < 10ms |
| Medium file diff (1-100KB) | < 100ms |
| Large file diff (1MB+) | < 1s |

### Themes

Built-in themes: `tokyo-night` (default), `github-dark`, `monokai`.

---

## Usage

### Basic Commands

```bash
# Compare two files
vex old_file.txt new_file.txt

# Side-by-side mode (default)
vex -s old.zig new.zig

# Unified diff mode
vex -u old.rs new.rs

# Enable AST-aware mode
vex --ast old.py new.py
```

### Reading from stdin

```bash
# Use '-' to read from stdin
cat file.txt | vex - other.txt

# Pipe git diff
git diff | vex -
git show HEAD | vex -
```

### Keybindings

| Key | Action |
| --- | --- |
| `j` / `↓` | Scroll down |
| `k` / `↑` | Scroll up |
| `n` / `N` | Next / Previous hunk |
| `Tab` | Toggle side-by-side / unified |
| `a` | Accept left side |
| `d` | Accept right side |
| `e` | Manual edit mode |
| `u` | Undo |
| `q` | Quit |

---

## Install

### Build from source (Zig 0.13.0+)

```bash
git clone https://github.com/ydah/vex.git
cd vex
zig build -Doptimize=ReleaseFast
sudo cp zig-out/bin/vex /usr/local/bin/
```

### Platform Support

| Platform | Status |
| --- | --- |
| Linux (x86_64) | ✅ Supported |
| Linux (aarch64) | ✅ Supported |
| macOS (x86_64) | ✅ Supported |
| macOS (Apple Silicon) | ✅ Supported |
| Windows | 🚧 Planned |

---

## Integrations

### Git

```bash
# Set as difftool
git config --global diff.tool vex
git config --global difftool.vex.cmd 'vex "$LOCAL" "$REMOTE"'

# Use with git
git difftool HEAD~3
```

---

## Customize

### Themes

```bash
export VEX_THEME=github-dark
vex file1.txt file2.txt
```

### Environment Variables

| Variable | Description | Default |
| --- | --- | --- |
| `VEX_THEME` | Color theme | `tokyo-night` |
| `VEX_PAGER` | Pager program | none |
| `NO_COLOR` | Disable colors when set | - |

---

## FAQ

### TUI looks broken

Make sure your terminal supports true color:

```bash
echo $COLORTERM
```

### How do I disable colors?

```bash
vex --no-color file1.txt file2.txt
# or
NO_COLOR=1 vex file1.txt file2.txt
```

---

## Project Goals

- Fast: startup < 50ms, small diff < 10ms
- Semantic: AST-aware diff for meaningful changes
- Visual-first: beautiful TUI with live editing
- Zero-config: useful out of the box

---

## Development

```bash
# Debug build
zig build

# Release build
zig build -Doptimize=ReleaseFast

# Tests
zig build test

# Run with arguments
zig build run -- file1.zig file2.zig
```

Contributions welcome. See `CONTRIBUTING.md` for workflow and style.

---

## License

MIT. See `LICENSE`.

## Credits

- [delta](https://github.com/dandavison/delta) and [difftastic](https://github.com/Wilfred/difftastic) for inspiration
- [Zig](https://ziglang.org/) for the language
- Myers diff algorithm based on "An O(ND) Difference Algorithm" by Eugene W. Myers
