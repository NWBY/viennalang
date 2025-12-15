const std = @import("std");
const Lexer = @import("lexer/lexer.zig").Lexer;
const Parser = @import("parser/parser.zig").Parser;
const Interpreter = @import("interpreter/interpreter.zig").Interpreter;
const ast = @import("parser/ast.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const backing_allocator = gpa.allocator();

    // Arena allocator - frees everything at once
    var arena = std.heap.ArenaAllocator.init(backing_allocator);
    defer arena.deinit(); // This frees ALL allocations at once
    const allocator = arena.allocator();

    // Test expressions
    const sources = [_][]const u8{
        "42",
        "5 + 3",
        "5 + 3 * 2",
        "10 - 2 - 3",
        "100 / 10",
        "2 * 3 + 4 * 5",
    };

    var interpreter = Interpreter.init(allocator);

    for (sources) |source| {
        std.debug.print("\nEvaluating: {s}\n", .{source});

        var lexer = Lexer.init(source);
        var parser = Parser.init(allocator, &lexer);

        const expr = try parser.parseExpression();
        const result = try interpreter.eval(expr);

        std.debug.print("Result: ", .{});
        result.print();
        std.debug.print("\n", .{});
    }
}
