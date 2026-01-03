const std = @import("std");
const Lexer = @import("lexer/lexer.zig").Lexer;
const Parser = @import("parser/parser.zig").Parser;
const Interpreter = @import("interpreter/interpreter.zig").Interpreter;
const TokenType = @import("lexer/token.zig").TokenType;
const TypeChecker = @import("interpreter/type_checker.zig").TypeChecker;
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

    std.debug.print("\n", .{});
    std.debug.print("Running: {s}\n", .{filename});
    std.debug.print("File contents: {s}\n", .{source});
    std.debug.print("{s}\n", .{"─" ** 50});

    // Parse and execute
    var lexer = Lexer.init(source);
    var parser = Parser.init(allocator, &lexer);
    var interpreter = Interpreter.init(allocator) catch {
        std.debug.print("Error: Failed to initialize interpreter\n", .{});
        std.process.exit(1);
    };
    var type_checker = TypeChecker.init(allocator);
    defer type_checker.deinit();

    while (!parser.currentTokenIs(TokenType.EOF)) {
        const stmt = parser.parseStatement() catch {
            std.process.exit(1);
        };

        const type_check_result = type_checker.checkStmt(stmt, null);
        switch (type_check_result) {
            .ok => {},
            .err => |err| {
                const msg = try err.format(allocator);
                defer allocator.free(msg);
                std.debug.print("Type error: {s}\n", .{msg});
                std.process.exit(1);
            },
        }

        // Check if it's an expression statement - if so, save the result
        switch (stmt.*) {
            .expr_stmt => |expr_stmt| {
                const result_expr = interpreter.evalExpr(&expr_stmt.expr) catch {
                    std.process.exit(1);
                };
                // Only print result if it's NOT a function call
                // (function calls might have side effects and print things themselves)
                if (expr_stmt.expr != .call) {
                    result_expr.print();
                    std.debug.print("\n", .{});
                }
            },
            .func_decl => {
                _ = try interpreter.evalStmt(stmt);
            },
            else => {
                // For const, var, func_decl, etc - just execute
                _ = try interpreter.evalStmt(stmt); // Discard the optional return value
            },
        }
    }
}
