// src/error.zig
const std = @import("std");

pub const ViennaError = struct {
    message: []const u8,
    line: usize,
    column: usize,
    source_line: []const u8,

    pub fn print(self: ViennaError) void {
        // Calculate the width needed for the box (use the longer of message or source line)
        const message_len = self.message.len;
        const source_len = self.source_line.len;
        const box_width = @max(message_len, source_len) + 4; // Add padding

        std.debug.print("\n┌", .{});
        var i: usize = 0;
        while (i < box_width - 2) : (i += 1) {
            std.debug.print("─", .{});
        }
        std.debug.print("┐\n", .{});
        std.debug.print("│ ", .{});
        std.debug.print("Error at line {d}, column {d}", .{ self.line, self.column });
        // Pad to box width
        const error_header_len = std.fmt.count("Error at line {}, column {}", .{ self.line, self.column });
        var padding: usize = box_width - error_header_len - 3;
        while (padding > 0) : (padding -= 1) {
            std.debug.print(" ", .{});
        }
        std.debug.print("│\n", .{});
        
        // Separator line
        std.debug.print("├", .{});
        i = 0;
        while (i < box_width - 2) : (i += 1) {
            std.debug.print("─", .{});
        }
        std.debug.print("┤\n", .{});
        
        // Source code line
        std.debug.print("│ ", .{});
        std.debug.print("{s}", .{self.source_line});
        padding = box_width - source_len - 3;
        while (padding > 0) : (padding -= 1) {
            std.debug.print(" ", .{});
        }
        std.debug.print("│\n", .{});
        
        // Pointer line
        std.debug.print("│ ", .{});
        i = 0;
        while (i < self.column - 1) : (i += 1) {
            std.debug.print(" ", .{});
        }
        std.debug.print("^", .{});
        padding = box_width - self.column - 3;
        while (padding > 0) : (padding -= 1) {
            std.debug.print(" ", .{});
        }
        std.debug.print("│\n", .{});
        
        // Error message
        std.debug.print("│ ", .{});
        std.debug.print("{s}", .{self.message});
        padding = box_width - message_len - 3;
        while (padding > 0) : (padding -= 1) {
            std.debug.print(" ", .{});
        }
        std.debug.print("│\n", .{});
        
        // Bottom border
        std.debug.print("└", .{});
        i = 0;
        while (i < box_width - 2) : (i += 1) {
            std.debug.print("─", .{});
        }
        std.debug.print("┘\n", .{});
    }
};
