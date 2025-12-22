// src/interpreter.zig
const std = @import("std");
const ast = @import("../parser/ast.zig");
const Value = @import("value.zig").Value;
const stdLibUtils = @import("../std/utils.zig");

// Explicitly define possible errors
pub const InterpreterError = error{ TypeError, DivisionByZero, NotImplemented, UndefinedVariable, OutOfMemory, CannotReassignConst, VariableAlreadyDeclared, FunctionAlreadyDeclared, UndefinedFunction, ArgumentCountMismatch };

pub const Variable = struct {
    value: Value,
    is_const: bool,
};

pub const Function = struct {
    parameters: []const ast.Parameter,
    return_type: ?[]const u8,
    body: []*ast.Stmt,
};

// Standard library function signature: takes interpreter, arguments, returns Value or error
pub const StdLibFunction = *const fn (*Interpreter, []const Value) InterpreterError!Value;

pub const Interpreter = struct {
    allocator: std.mem.Allocator,
    environment: std.StringHashMap(Variable),
    functions: std.StringHashMap(Function),
    std_lib_functions: std.StringHashMap(StdLibFunction),

    pub fn init(allocator: std.mem.Allocator) !Interpreter {
        var interpreter = Interpreter{
            .allocator = allocator,
            .environment = std.StringHashMap(Variable).init(allocator),
            .functions = std.StringHashMap(Function).init(allocator),
            .std_lib_functions = std.StringHashMap(StdLibFunction).init(allocator),
        };

        try interpreter.registerStdLibFunction("print", stdLibUtils.print);

        return interpreter;
    }

    pub fn deinit(self: *Interpreter) void {
        self.environment.deinit(); // Clean up
        self.functions.deinit();
        self.std_lib_functions.deinit();
    }

    fn registerStdLibFunction(self: *Interpreter, name: []const u8, function: StdLibFunction) !void {
        try self.std_lib_functions.put(name, function);
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
                if (self.std_lib_functions.get(call.name)) |function| {
                    // Evaluate arguments first (same pattern as user-defined functions)
                    var arg_values = try std.ArrayList(Value).initCapacity(self.allocator, call.arguments.len);
                    for (call.arguments) |arg_expr| {
                        const arg_value = try self.evalExpr(arg_expr);
                        try arg_values.append(self.allocator, arg_value);
                    }

                    // Now call with evaluated values
                    return try function(self, arg_values.items);
                }

                if (!self.functions.contains(call.name)) {
                    return InterpreterError.UndefinedFunction;
                }

                const function = self.functions.getPtr(call.name).?;

                if (function.parameters.len != call.arguments.len) {
                    return InterpreterError.ArgumentCountMismatch;
                }

                var arg_values = try std.ArrayList(Value).initCapacity(self.allocator, call.arguments.len);
                for (call.arguments) |arg_expr| {
                    const arg_value = try self.evalExpr(arg_expr);
                    try arg_values.append(self.allocator, arg_value);
                }

                // Save reference to current environment
                const old_environment = self.environment;
                // Create new environment for function scope
                var new_environment = std.StringHashMap(Variable).init(self.allocator);
                defer new_environment.deinit();
                self.environment = new_environment;

                // Bind parameters to argument values
                for (function.parameters, arg_values.items) |param, arg_value| {
                    try self.environment.put(param.name, Variable{
                        .value = arg_value,
                        .is_const = true, // or false, depending on your language design
                    });
                }

                // Execute function body
                var return_value: ?Value = null;
                for (function.body) |stmt| {
                    const stmt_result = try self.evalStmt(stmt);
                    if (stmt_result) |value| {
                        // Return statement encountered - break out early
                        return_value = value;
                        break;
                    }
                }

                // Restore old environment
                self.environment = old_environment;

                // Return the value (or null/default if no return statement)
                return return_value orelse Value{ .null_value = {} };
            },
        };
    }

    fn evalBinary(self: *Interpreter, binary: ast.BinaryExpr) InterpreterError!Value {
        // Evaluate left and right sides
        const left = try self.evalExpr(binary.left);
        const right = try self.evalExpr(binary.right);

        // Handle integer operations
        if (left == .int and right == .int) {
            const left_val = left.int;
            const right_val = right.int;

            return switch (binary.operator) {
                .Add => Value{ .int = left_val + right_val },
                .Subtract => Value{ .int = left_val - right_val },
                .Multiply => Value{ .int = left_val * right_val },
                .Divide => blk: {
                    if (right_val == 0) return InterpreterError.DivisionByZero;
                    break :blk Value{ .int = @divTrunc(left_val, right_val) };
                },
                .DoubleEqual => Value{ .bool = left_val == right_val },
                .NotEqual => Value{ .bool = left_val != right_val },
                .GreaterThan => Value{ .bool = left_val > right_val },
                .LessThan => Value{ .bool = left_val < right_val },
                .GreaterThanEqual => Value{ .bool = left_val >= right_val },
                .LessThanEqual => Value{ .bool = left_val <= right_val },
            };
        }

        // Handle string comparisons
        if (left == .string and right == .string) {
            const left_str = left.string;
            const right_str = right.string;

            return switch (binary.operator) {
                .DoubleEqual => Value{ .bool = std.mem.eql(u8, left_str, right_str) },
                .NotEqual => Value{ .bool = !std.mem.eql(u8, left_str, right_str) },
                else => return InterpreterError.TypeError,
            };
        }

        // Handle boolean comparisons
        if (left == .bool and right == .bool) {
            return switch (binary.operator) {
                .DoubleEqual => Value{ .bool = left.bool == right.bool },
                .NotEqual => Value{ .bool = left.bool != right.bool },
                else => return InterpreterError.TypeError,
            };
        }

        return InterpreterError.TypeError;
    }

    pub fn evalStmt(self: *Interpreter, stmt: *ast.Stmt) InterpreterError!?Value {
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

                // return null and continue evaluation
                return null;
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

                // return null and continue evaluation
                return null;
            },
            .expr_stmt => |expr_stmt| {
                // Just evaluate the expression and throw away the result
                _ = try self.evalExpr(&expr_stmt.expr);

                // return null and continue evaluation
                return null;
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

                // return null and continue evaluation
                return null;
            },
            .return_stmt => |return_stmt| {
                if (return_stmt.value) |ret_expr| {
                    const value = try self.evalExpr(&ret_expr);
                    return value; // Return the value (signals early exit)
                } else {
                    return Value{ .null_value = {} }; // return; with no value
                }
            },
            .if_stmt => |if_stmt| {
                const condition = try self.evalExpr(&if_stmt.condition);
                if (condition != .bool) {
                    return InterpreterError.TypeError;
                }
                if (condition.bool) {
                    for (if_stmt.then_branch) |then_stmt| {
                        const stmt_result = try self.evalStmt(then_stmt);
                        if (stmt_result) |value| {
                            return value;
                        } else {
                            return null;
                        }
                    }
                } else {
                    if (if_stmt.else_branch) |else_branch| {
                        for (else_branch) |else_stmt| {
                            const stmt_result = try self.evalStmt(else_stmt);
                            if (stmt_result) |value| {
                                return value;
                            }
                        }
                    }
                }
                return null;
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
