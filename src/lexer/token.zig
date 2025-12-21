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

    // Comparisons
    DOUBLE_EQUAL,
    NOT_EQUAL,
    GREATER_THAN,
    LESS_THAN,
    GREATER_THAN_EQUAL,
    LESS_THAN_EQUAL,

    // Delimiters
    LPAREN,
    RPAREN,
    LBRACE,
    RBRACE,
    COMMA,
    COLON,

    // Other
    IDENT,
    BANG,
    EOF,
};

pub const Token = struct {
    type: TokenType,
    lexeme: []const u8,
    line: usize,
    column: usize,
};
