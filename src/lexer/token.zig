pub const TokenType = enum {
    INT,
    STRING,
    TRUE,
    FALSE,

    // Keywords
    CONST,
    VAR,
    FUNC,
    RETURN,
    IF,
    ELSE,

    // Operators
    PLUS,
    MINUS,
    STAR,
    SLASH,
    ASSIGN,
    SEMICOLON,
    GREATER,

    // Delimiters
    LPAREN,
    RPAREN,
    LBRACE,
    RBRACE,
    COMMA,
    COLON,

    // Other
    IDENT,
    EOF,
};

pub const Token = struct {
    type: TokenType,
    lexeme: []const u8,
    line: usize,
    column: usize,
};
