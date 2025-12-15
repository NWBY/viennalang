// src/error.zig
const std = @import("std");

pub const ViennaError = struct {
    message: []const u8,
    line: usize,
    column: usize,
    source_line: []const u8,

    pub fn print(self: ViennaError) void {
        std.debug.print("\nError at line {d}, column {d}:\n", .{ self.line, self.column });
        std.debug.print("{s}\n", .{self.source_line});

        // Print pointer to error location
        var i: usize = 0;
        while (i < self.column - 1) : (i += 1) {
            std.debug.print(" ", .{});
        }
        std.debug.print("^\n", .{});
        std.debug.print("{s}\n", .{self.message});
    }
};
