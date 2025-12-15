// src/interpreter.zig
const std = @import("std");
const ast = @import("../parser/ast.zig");
const Value = @import("value.zig").Value;

// Explicitly define possible errors
pub const InterpreterError = error{
    TypeError,
    DivisionByZero,
    NotImplemented,
};

pub const Interpreter = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Interpreter {
        return Interpreter{
            .allocator = allocator,
        };
    }

    pub fn eval(self: *Interpreter, expr: *ast.Expr) InterpreterError!Value {
        return switch (expr.*) {
            .int_literal => |lit| Value{ .int = lit.value },
            .string_literal => |lit| Value{ .string = lit.value },
            .bool_literal => |lit| Value{ .bool = lit.value },
            .binary => |bin| try self.evalBinary(bin),
            else => error.NotImplemented,
        };
    }

    fn evalBinary(self: *Interpreter, binary: ast.BinaryExpr) InterpreterError!Value {
        // Evaluate left and right sides
        const left = try self.eval(binary.left);
        const right = try self.eval(binary.right);

        // Both sides must be integers for now
        if (left != .int or right != .int) {
            return InterpreterError.TypeError;
        }

        // Perform the operation
        const result = switch (binary.operator) {
            .Add => left.int + right.int,
            .Subtract => left.int - right.int,
            .Multiply => left.int * right.int,
            .Divide => blk: {
                if (right.int == 0) {
                    return InterpreterError.DivisionByZero;
                }
                break :blk @divTrunc(left.int, right.int);
            },
        };

        return Value{ .int = result };
    }
};
