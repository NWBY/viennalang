const std = @import("std");
const Interpreter = @import("../interpreter/interpreter.zig").Interpreter;
const Value = @import("../interpreter/value.zig").Value;
const InterpreterError = @import("../interpreter/interpreter.zig").InterpreterError;

pub fn print(_: *Interpreter, arguments: []const Value) InterpreterError!Value {
    if (arguments.len != 1) {
        return InterpreterError.ArgumentCountMismatch;
    }

    const argument = arguments[0];
    std.debug.print("vienna output: ", .{});
    argument.print();
    std.debug.print("\n\n", .{});

    return Value{ .null_value = {} };
}
