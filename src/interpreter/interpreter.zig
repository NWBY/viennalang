// src/interpreter.zig
const std = @import("std");
const ast = @import("../parser/ast.zig");
const Value = @import("value.zig").Value;

// Explicitly define possible errors
pub const InterpreterError = error{ TypeError, DivisionByZero, NotImplemented, UndefinedVariable, OutOfMemory, CannotReassignConst, VariableAlreadyDeclared, FunctionAlreadyDeclared, UndefinedFunction };

pub const Variable = struct {
    value: Value,
    is_const: bool,
};

pub const Function = struct {
    parameters: []const ast.Parameter,
    return_type: ?[]const u8,
    body: []*ast.Stmt,
};

pub const Interpreter = struct {
    allocator: std.mem.Allocator,
    environment: std.StringHashMap(Variable),
    functions: std.StringHashMap(Function),

    pub fn init(allocator: std.mem.Allocator) Interpreter {
        return Interpreter{
            .allocator = allocator,
            .environment = std.StringHashMap(Variable).init(allocator),
            .functions = std.StringHashMap(Function).init(allocator),
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
                if (self.environment.get(ident.name)) |variable| {
                    return variable.value;
                } else {
                    return InterpreterError.UndefinedVariable;
                }
            },
            .assignment => |assign| {
                const value = try self.evalExpr(assign.value);

                if (self.environment.getPtr(assign.name)) |variable| {
                    if (variable.is_const) {
                        return InterpreterError.CannotReassignConst;
                    }
                    variable.value = value;
                } else {
                    return InterpreterError.UndefinedVariable;
                }

                return value;
            },
            .call => |call| {
                if (!self.functions.contains(call.name)) {
                    return InterpreterError.UndefinedFunction;
                }

                const function = self.functions.getPtr(call.name);

                if (function.parameters.len != call.arguments.len) {
                    return InterpreterError.ArgumentCountMismatch;
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
                if (self.environment.contains(decl.name)) {
                    return InterpreterError.VariableAlreadyDeclared;
                }

                // 1. Evaluate the value expression
                const value = try self.evalExpr(&decl.value);

                // 2. Store it in the environment
                try self.environment.put(decl.name, Variable{
                    .value = value,
                    .is_const = true,
                });
            },
            .var_decl => |decl| {
                if (self.environment.contains(decl.name)) {
                    return InterpreterError.VariableAlreadyDeclared;
                }

                // 1. Evaluate the value expression
                const value = try self.evalExpr(&decl.value);

                // 2. Store it in the environment
                try self.environment.put(decl.name, Variable{
                    .value = value,
                    .is_const = false,
                });
            },
            .expr_stmt => |expr_stmt| {
                // Just evaluate the expression and throw away the result
                _ = try self.evalExpr(&expr_stmt.expr);
            },
            .func_decl => |func_decl| {
                if (self.functions.contains(func_decl.name)) {
                    return InterpreterError.FunctionAlreadyDeclared;
                }

                try self.functions.put(func_decl.name, Function{
                    .parameters = func_decl.parameters,
                    .return_type = func_decl.return_type,
                    .body = func_decl.body,
                });
            },
            .return_stmt => {
                return InterpreterError.NotImplemented;
            },
        }
    }

    // Helper function for when assignment expressions are added
    pub fn assignVariable(self: *Interpreter, name: []const u8, value: Value) InterpreterError!void {
        if (self.environment.getPtr(name)) |variable| {
            if (variable.is_const) {
                return InterpreterError.CannotReassignConst;
            }
            variable.value = value;
        } else {
            return InterpreterError.UndefinedVariable;
        }
    }
};
