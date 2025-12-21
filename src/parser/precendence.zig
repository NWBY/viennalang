const TokenType = @import("../lexer/token.zig").TokenType;

pub const Precedence = enum {
    LOWEST,
    EQUALITY, // == !=
    COMPARISON, // > < >= <=
    SUM, // + -
    PRODUCT, // * /
    PREFIX, // -x, !x
    CALL, // function()
};

pub fn getTokenPrecedence(token_type: TokenType) Precedence {
    return switch (token_type) {
        TokenType.PLUS, TokenType.MINUS => Precedence.SUM,
        TokenType.STAR, TokenType.SLASH => Precedence.PRODUCT,
        TokenType.DOUBLE_EQUAL, TokenType.NOT_EQUAL => Precedence.EQUALITY,
        TokenType.GREATER_THAN, TokenType.LESS_THAN, TokenType.GREATER_THAN_EQUAL, TokenType.LESS_THAN_EQUAL => Precedence.COMPARISON,
        TokenType.GREATER_THAN_EQUAL, TokenType.LESS_THAN_EQUAL => Precedence.COMPARISON,
        else => Precedence.LOWEST,
    };
}
