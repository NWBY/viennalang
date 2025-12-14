const std = @import("std");
const Token = @import("token.zig").Token;
const TokenType = @import("token.zig").TokenType;

pub const Lexer = struct {
    source: []const u8,
    current: usize,
    line: usize,

    pub fn init(source: []const u8) Lexer {
        return Lexer{
            .source = source,
            .current = 0,
            .line = 1,
        };
    }

    fn isAtEnd(self: *Lexer) bool {
        return self.current >= self.source.len;
    }

    fn advance(self: *Lexer) u8 {
        const c = self.source[self.current];
        self.current += 1;
        return c;
    }

    fn peek(self: *Lexer) u8 {
        if (self.isAtEnd()) return 0;
        return self.source[self.current];
    }

    fn makeToken(self: *Lexer, tokenType: TokenType) Token {
        return Token{
            .type = tokenType,
            .lexeme = self.source[self.start - 1 .. self.current],
            .line = self.line,
        };
    }

    fn errorToken(self: *Lexer, message: []const u8) Token {
        return Token{
            .type = TokenType.EOF, // TODO: make a proper error token type
            .lexeme = message,
            .line = self.line,
        };
    }
};
