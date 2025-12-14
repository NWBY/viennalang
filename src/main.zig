const std = @import("std");
const Lexer = @import("lexer/lexer.zig").Lexer;
const TokenType = @import("lexer/token.zig").TokenType;

pub fn main() !void {
    const source =
        \\const x = 42;
        \\var y = "hello";
        \\y = x + 10;
    ;

    var lexer = Lexer.init(source);

    while (true) {
        const token = lexer.nextToken();
        std.debug.print("{s}: {s}\n", .{ @tagName(token.type), token.lexeme });

        if (token.type == TokenType.EOF) break;
    }
}
