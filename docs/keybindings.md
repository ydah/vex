# Keybindings

Complete reference for vex keyboard shortcuts.

## Navigation

| Key | Action | Description |
|-----|--------|-------------|
| `j` | Scroll down | Move down one line |
| `k` | Scroll up | Move up one line |
| `↓` | Scroll down | Arrow key alternative |
| `↑` | Scroll up | Arrow key alternative |
| `Space` | Page down | Scroll down one page |
| `b` | Page up | Scroll up one page |
| `Page Down` | Page down | Scroll down one page |
| `Page Up` | Page up | Scroll up one page |
| `g` | Go to top | Jump to first line |
| `G` | Go to bottom | Jump to last line |
| `n` | Next hunk | Jump to next change block |
| `N` | Previous hunk | Jump to previous change block |
| `Ctrl+d` | Half page down | Scroll down half a page |
| `Ctrl+u` | Half page up | Scroll up half a page |

## View Modes

| Key | Action | Description |
|-----|--------|-------------|
| `Tab` | Toggle mode | Switch between side-by-side and unified |
| `s` | Side-by-side | Switch to side-by-side view |
| `u` | Unified | Switch to unified diff view |
| `w` | Word diff | Toggle word-level diff highlighting |
| `l` | Line numbers | Toggle line number display |
| `c` | Colors | Toggle color output |

## Editing

| Key | Action | Description |
|-----|--------|-------------|
| `a` | Accept left | Use the left (old) version |
| `d` | Accept right | Use the right (new) version |
| `e` | Edit mode | Enter manual editing mode |
| `Escape` | Exit edit | Exit editing mode |
| `u` | Undo | Undo last change |
| `Ctrl+r` | Redo | Redo last undone change |

## In Edit Mode

| Key | Action |
|-----|--------|
| Arrow keys | Move cursor |
| `h/j/k/l` | Move cursor (vim-style) |
| Any character | Insert at cursor |
| `Backspace` | Delete character before cursor |
| `Delete` | Delete character at cursor |
| `Enter` | Insert newline |
| `Escape` | Exit edit mode |

## Search

| Key | Action | Description |
|-----|--------|-------------|
| `/` | Search forward | Start forward search |
| `?` | Search backward | Start backward search |
| `Enter` | Execute search | Find next match |
| `Escape` | Cancel search | Exit search mode |
| `n` | Next match | Jump to next search result |
| `N` | Previous match | Jump to previous search result |

## File Operations

| Key | Action | Description |
|-----|--------|-------------|
| `:w` | Save | Save changes to file |
| `:q` | Quit | Exit vex |
| `:wq` | Save and quit | Save changes and exit |
| `:q!` | Force quit | Exit without saving |

## General

| Key | Action | Description |
|-----|--------|-------------|
| `q` | Quit | Exit vex |
| `?` | Help | Show keybinding help |
| `Ctrl+l` | Redraw | Refresh the screen |

## Customization

Keybindings can be customized in the configuration file:

```
# ~/.config/vex/config

[keybindings]
scroll_down = "j"
scroll_up = "k"
next_hunk = "n"
prev_hunk = "N"
accept_left = "a"
accept_right = "d"
quit = "q"
```

## Vim-like Philosophy

vex follows vim-like keybinding conventions:

- `h/j/k/l` for movement
- `/` for search
- `:` for commands
- `u` for undo
- Modal editing (normal → insert → normal)

This makes vex intuitive for vim users while remaining accessible for others.
