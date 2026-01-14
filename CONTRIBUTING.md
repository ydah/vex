# Contributing to vex

Thank you for considering contributing to vex! This document provides guidelines and information for contributors.

## How to Contribute

### Reporting Bugs

If you find a bug, please open an issue with:

1. A clear, descriptive title
2. Steps to reproduce the bug
3. Expected vs actual behavior
4. Your environment (OS, Zig version, terminal)
5. Any relevant output or screenshots

### Suggesting Features

Feature suggestions are welcome! Please open an issue with:

1. A clear description of the feature
2. Why this feature would be useful
3. Possible implementation approaches (if any)

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests (`zig build test`)
5. Format code (`zig fmt src/`)
6. Commit with a descriptive message
7. Push to your fork
8. Open a Pull Request

## Development Setup

### Prerequisites

- Zig 0.13.0 or later
- Git

### Building

```bash
git clone https://github.com/ydah/vex.git
cd vex
zig build
```

### Running Tests

```bash
zig build test
```

### Code Style

- Follow Zig's standard style guidelines
- Use `zig fmt` before committing
- Add doc comments for public functions
- Keep functions focused and small
- Handle errors properly (no panics in library code)

## Project Structure

```
src/
├── main.zig           # Entry point
├── cli.zig            # CLI parsing
├── core/              # Core diff algorithms
├── output/            # Output formatters
├── ui/                # TUI components
├── editor/            # Editor functionality
└── utils/             # Utilities
```

## Areas Where Help is Needed

- **Language Support**: Adding Tree-sitter grammars for more languages
- **AST Algorithms**: Improving diff accuracy for complex changes
- **Performance**: Optimizations for large files
- **Documentation**: Improving docs and adding examples
- **Translations**: Translating docs to other languages
- **Windows**: Adding Windows support

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on constructive feedback
- Assume good intentions

## Questions?

Feel free to open an issue or discussion if you have any questions!
