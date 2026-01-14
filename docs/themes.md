# Color Themes

vex supports multiple color themes for customizing the appearance of diffs.

## Built-in Themes

### Tokyo Night (Default)

A modern, eye-friendly dark theme inspired by the Tokyo Night color scheme.

```
Background:   #1a1b26
Foreground:   #c0caf5
Addition:     #9ece6a (green)
Deletion:     #f7768e (red)
Modification: #7aa2f7 (blue)
Line Numbers: #565f89 (gray)
Hunk Header:  #7aa2f7 (blue)
```

Best for: Long coding sessions, low-light environments

### GitHub Dark

GitHub-inspired dark theme for a familiar look.

```
Background:   #0d1117
Foreground:   #c9d1d9
Addition:     #3fb950 (green)
Deletion:     #f85149 (red)
Modification: #d29922 (yellow)
Line Numbers: #6e7681 (gray)
Hunk Header:  #79c0ff (blue)
```

Best for: GitHub users, code review consistency

### Monokai

Classic Monokai colors for a vibrant look.

```
Background:   #272822
Foreground:   #f8f8f2
Addition:     #a6e22e (green)
Deletion:     #f92672 (pink)
Modification: #66d9ef (cyan)
Line Numbers: #75715e (gray)
Hunk Header:  #ae81ff (purple)
```

Best for: Fans of classic syntax highlighting

## Using Themes

### Via Environment Variable

```bash
export VEX_THEME=github-dark
vex file1.txt file2.txt
```

### Via Command Line

```bash
vex --theme=monokai file1.txt file2.txt
```

### Via Configuration File

```
# ~/.config/vex/config
theme = "tokyo-night"
```

## Theme Names

| Display Name | Config Value |
|--------------|--------------|
| Tokyo Night | `tokyo-night` |
| GitHub Dark | `github-dark` |
| Monokai | `monokai` |

## Disabling Colors

For pipes or color-impaired terminals:

```bash
# Via flag
vex --no-color file1.txt file2.txt

# Via environment variable
NO_COLOR=1 vex file1.txt file2.txt
```

## Custom Themes (Coming Soon)

Support for custom themes via configuration file is planned:

```
# ~/.config/vex/themes/my-theme.toml

[colors]
background = "#282c34"
foreground = "#abb2bf"
addition = "#98c379"
deletion = "#e06c75"
modification = "#61afef"
line_numbers = "#5c6370"
hunk_header = "#c678dd"
```

## Terminal Requirements

For best color reproduction:

- **True Color (24-bit)**: Recommended for accurate theme colors
- **256 Colors**: Supported with approximate colors
- **16 Colors**: Basic support, colors may vary

Check your terminal's color support:

```bash
echo $COLORTERM  # Should show "truecolor" or "24bit"
```
