const TokenType = @import("../lexer/token.zig").TokenType;

pub const Precedence = enum {
    LOWEST,
    SUM, // + -
    PRODUCT, // * /
    PREFIX, // -x, !x
    CALL, // function()
};

pub fn getTokenPrecedence(token_type: TokenType) Precedence {
    return switch (token_type) {
        TokenType.PLUS, TokenType.MINUS => Precedence.SUM,
        TokenType.STAR, TokenType.SLASH => Precedence.PRODUCT,
        else => Precedence.LOWEST,
    };
}
