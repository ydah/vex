# Comparison with Alternatives

A detailed comparison of vex with other diff tools.

## Quick Comparison

| Feature | vex | diff | delta | difftastic |
|---------|-----|------|-------|------------|
| Syntax Highlighting | ✅ | ❌ | ✅ | ✅ |
| AST-Aware | ✅ | ❌ | ❌ | ✅ |
| Side-by-Side View | ✅ | ❌ | ✅ | ❌ |
| Inline Editing | ✅ | ❌ | ❌ | ❌ |
| TUI Interface | ✅ | ❌ | ❌ | ❌ |
| Git Integration | ✅ | ❌ | ✅ | ✅ |
| Large File Performance | ✅ | ✅ | ⚠️ | ⚠️ |
| Language Support | 40+ | N/A | 200+ | 50+ |
| Written In | Zig | C | Rust | Rust |
| Binary Size | ~2MB | ~100KB | ~10MB | ~30MB |

## Detailed Comparison

### vs. GNU diff

**diff** is the classic Unix diff utility.

| Aspect | vex | diff |
|--------|-----|------|
| Output Format | Unified, side-by-side | Unified, context, normal |
| Colors | Yes | No (needs colordiff) |
| Interactivity | Full TUI | None |
| Editing | Yes | No |
| Speed | Very fast | Fastest |
| Dependencies | None | None |

**When to use diff:**
- You need the simplest, most portable solution
- Scripting and automation
- Minimal resource usage

**When to use vex:**
- Code review with visual feedback
- Interactive merge operations
- When you want to understand changes quickly

### vs. delta

**delta** is a syntax-highlighting pager for git diff output.

| Aspect | vex | delta |
|--------|-----|-------|
| Primary Use | Standalone diff tool | Git diff pager |
| TUI Mode | Yes | No |
| Editing | Yes | No |
| Side-by-side | Yes | Yes |
| Git Integration | Yes | Deep |
| Themes | 3 built-in | 10+ |

**When to use delta:**
- You want enhanced git diff output
- You don't need editing capabilities
- You prefer pager-style viewing

**When to use vex:**
- You want interactive editing
- You compare arbitrary files
- You want a full TUI experience

### vs. difftastic

**difftastic** is a structural diff tool that understands code syntax.

| Aspect | vex | difftastic |
|--------|-----|------------|
| AST Parsing | Tree-sitter | Tree-sitter |
| View Mode | TUI | CLI output |
| Editing | Yes | No |
| Side-by-side | Yes | Inline |
| Performance | Fast | Can be slow |
| Language Support | 40+ | 50+ |

**When to use difftastic:**
- You only need to view diffs
- You want maximum language support
- You prefer simple CLI output

**When to use vex:**
- You want to edit while reviewing
- You prefer side-by-side view
- You want better performance on large files

### vs. meld

**meld** is a visual diff and merge tool with a GUI.

| Aspect | vex | meld |
|--------|-----|------|
| Interface | TUI | GUI |
| Platform | All | All (with GUI) |
| Resource Usage | Low | Higher |
| Editing | Yes | Yes |
| 3-way Merge | Planned | Yes |

**When to use meld:**
- You prefer GUI tools
- You need 3-way merge
- You're not in a terminal

**When to use vex:**
- You work in the terminal
- You want keyboard-driven workflow
- You need lower resource usage

## Performance Benchmarks

Comparing diff of Linux kernel files:

| Tool | Time (1MB file) | Memory |
|------|-----------------|--------|
| diff | 50ms | 5MB |
| vex | 200ms | 15MB |
| delta | 500ms | 50MB |
| difftastic | 2s | 200MB |

*Note: These are approximate values and may vary by system and file content.*

## Choosing the Right Tool

### Use vex if you:
- Want a modern TUI experience
- Need to edit while reviewing diffs
- Care about performance
- Like vim-style keybindings
- Want semantic diff understanding

### Use diff if you:
- Need maximum compatibility
- Are scripting
- Want the smallest footprint

### Use delta if you:
- Primarily use git
- Don't need editing
- Want beautiful pager output

### Use difftastic if you:
- Only need to view diffs
- Want maximum language support
- Don't care about editing

## Migration Guide

### From diff

```bash
# Instead of
diff old.txt new.txt

# Use
vex old.txt new.txt
```

### From delta

```bash
# Instead of
git diff | delta

# Use
git diff | vex -
```

### From difftastic

```bash
# Instead of
difft old.py new.py

# Use
vex --ast old.py new.py
```
