// src/value.zig
const std = @import("std");

pub const Value = union(enum) {
    int: i64,
    string: []const u8,
    bool: bool,
    null_value: void,

    pub fn print(self: Value) void {
        switch (self) {
            .int => |v| std.debug.print("{d}", .{v}),
            .string => |v| std.debug.print("\"{s}\"", .{v}),
            .bool => |v| std.debug.print("{}", .{v}),
            .null_value => std.debug.print("null", .{}),
        }
    }
};
