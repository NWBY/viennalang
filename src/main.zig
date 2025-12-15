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

    // Get command line arguments
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: vienna <file.vn>\n", .{});
        std.process.exit(1);
    }

    const filename = args[1];

    // Check file extension
    if (!std.mem.endsWith(u8, filename, ".vn")) {
        std.debug.print("Error: File must have .vn extension\n", .{});
        std.process.exit(1);
    }

    // Read the file
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    const source = try file.readToEndAlloc(allocator, 1024 * 1024); // Max 1MB
    defer allocator.free(source);

    std.debug.print("Running: {s}\n", .{filename});
    std.debug.print("File contents: {s}\n", .{source});
    std.debug.print("{s}\n", .{"─" ** 50});

    // Parse and execute
    var lexer = Lexer.init(source);
    var parser = Parser.init(allocator, &lexer);
    var interpreter = Interpreter.init(allocator);

    const expr = parser.parseExpression() catch |err| {
        std.debug.print("Parse error: {}\n", .{err});
        std.process.exit(1);
    };

    const result = interpreter.eval(expr) catch |err| {
        std.debug.print("Runtime error: {}\n", .{err});
        std.process.exit(1);
    };

    std.debug.print("Result: ", .{});
    result.print();
    std.debug.print("\n", .{});
}
