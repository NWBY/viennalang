// src/interpreter.zig
const std = @import("std");
const ast = @import("../parser/ast.zig");
const Value = @import("value.zig").Value;

// Explicitly define possible errors
pub const InterpreterError = error{ TypeError, DivisionByZero, NotImplemented, UndefinedVariable, OutOfMemory };

pub const Interpreter = struct {
    allocator: std.mem.Allocator,
    environment: std.StringHashMap(Value),

    pub fn init(allocator: std.mem.Allocator) Interpreter {
        return Interpreter{
            .allocator = allocator,
            .environment = std.StringHashMap(Value).init(allocator),
        };
    }

    pub fn deinit(self: *Interpreter) void {
        self.environment.deinit(); // Clean up
    }

    pub fn evalExpr(self: *Interpreter, expr: *const ast.Expr) InterpreterError!Value {
        return switch (expr.*) {
            .int_literal => |lit| Value{ .int = lit.value },
            .string_literal => |lit| Value{ .string = lit.value },
            .bool_literal => |lit| Value{ .bool = lit.value },
            .binary => |bin| try self.evalBinary(bin),
            .identifier => |ident| {
                if (self.environment.get(ident.name)) |value| {
                    return value;
                } else {
                    return InterpreterError.UndefinedVariable;
                }
            },
        };
    }

    fn evalBinary(self: *Interpreter, binary: ast.BinaryExpr) InterpreterError!Value {
        // Evaluate left and right sides
        const left = try self.evalExpr(binary.left);
        const right = try self.evalExpr(binary.right);

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

    pub fn evalStmt(self: *Interpreter, stmt: *ast.Stmt) InterpreterError!void {
        switch (stmt.*) {
            .const_decl => |decl| {
                // 1. Evaluate the value expression
                const value = try self.evalExpr(&decl.value);

                // 2. Store it in the environment
                try self.environment.put(decl.name, value);
            },
            .var_decl => |_| {
                // Similar to const_decl - we'll add this later
                return InterpreterError.NotImplemented;
            },
            .expr_stmt => |expr_stmt| {
                // Just evaluate the expression and throw away the result
                _ = try self.evalExpr(&expr_stmt.expr);
            },
            .return_stmt => {
                return InterpreterError.NotImplemented;
            },
        }
    }
};
