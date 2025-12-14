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
};
