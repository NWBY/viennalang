const std = @import("std");
const Lexer = @import("lexer/lexer.zig").Lexer;

pub fn main() !void {
    const source =
        \\const x = 42;
        \\var y = "hello";
        \\y = x + 10;
    ;

    var lexer = Lexer.init(source);
}
