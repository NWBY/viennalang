const std = @import("std");
const Lexer = @import("lexer/lexer.zig").Lexer;
const Parser = @import("parser/parser.zig").Parser;
const ast = @import("parser/ast.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const backing_allocator = gpa.allocator();

    // Arena allocator - frees everything at once
    var arena = std.heap.ArenaAllocator.init(backing_allocator);
    defer arena.deinit(); // This frees ALL allocations at once
    const allocator = arena.allocator();

    // Test different expressions
    const sources = [_][]const u8{
        "42",
        "\"hello world\"",
        "true",
        "false",
    };

    for (sources) |source| {
        std.debug.print("\nParsing: {s}\n", .{source});

        var lexer = Lexer.init(source);
        var parser = Parser.init(allocator, &lexer);

        const expr = try parser.parseExpression();

        // Print what we parsed
        switch (expr.*) {
            .int_literal => |lit| {
                std.debug.print("  -> Integer: {d}\n", .{lit.value});
            },
            .string_literal => |lit| {
                std.debug.print("  -> String: {s}\n", .{lit.value});
            },
            .bool_literal => |lit| {
                std.debug.print("  -> Boolean: {}\n", .{lit.value});
            },
            else => {
                std.debug.print("  -> Unknown expression type\n", .{});
            },
        }
    }
}
