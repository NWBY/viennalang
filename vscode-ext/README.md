# Vienna Language VS Code Extension

Syntax highlighting support for Vienna language files (`.vn`).

## Features

- Syntax highlighting for Vienna language
- Support for keywords (`const`, `var`, `func`, `return`, `if`, `else`)
- Type highlighting (`int`, `string`, `void`, `bool`)
- Literal highlighting (integers, strings, booleans)
- Operator highlighting
- Comment support (`//`)
- Auto-closing brackets and quotes
- Smart indentation

## Installation

### From Source

1. Clone this repository
2. Open VS Code
3. Press `F5` to open a new window with the extension loaded
4. Or package the extension: `vsce package` (requires `vsce` tool: `npm install -g vsce`)

### Development

1. Open the `vscode-ext` directory in VS Code
2. Press `F5` to launch a new Extension Development Host window
3. Open a `.vn` file to see syntax highlighting

## Language Features

The extension provides syntax highlighting for:

- **Keywords**: `const`, `var`, `func`, `return`, `if`, `else`
- **Types**: `int`, `string`, `void`, `bool`
- **Literals**: integers, strings (double-quoted), booleans (`true`, `false`)
- **Operators**: `+`, `-`, `*`, `/`, `=`, `>`, `->`, etc.
- **Comments**: Single-line comments with `//`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT




