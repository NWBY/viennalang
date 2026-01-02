const std = @import("std");

pub const EventWriter = struct {
    file: std.fs.File,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, filepath: []const u8) !EventWriter {
        const file = try std.fs.cwd().createFile(filepath, .{ .truncate = true });
        return EventWriter{
            .file = file,
            .allocator = allocator,
        };
    }

    pub fn emit(self: *EventWriter, stage: []const u8, event_type: []const u8, data: anytype) !void {
        const json = try std.json.stringifyAlloc(self.allocator, .{
            .stage = stage,
            .event = event_type,
            .timestamp = std.time.timestamp(),
            .data = data,
        }, .{});
        defer self.allocator.free(json);

        try self.file.writer().writeAll(json);
        try self.file.writer().writeAll("\n");
        try self.file.writer().flush();
    }

    pub fn deinit(self: *EventWriter) void {
        self.file.close();
    }
};
