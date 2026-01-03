const std = @import("std");
const ast = @import("../parser/ast.zig");
const Function = @import("interpreter.zig").Function;

pub const TypeCheckerError = error{ UndefinedVariable, InvalidType, TypeMismatch, RecursiveType, InfiniteLoop, UnexpectedEOF, UnexpectedToken, UndefinedFunction, ArgumentCountMismatch, VariableAlreadyDeclared, FunctionAlreadyDeclared, OutOfMemory, UnexpectedReturnOutsideFunction };

pub const Type = enum {
    Int,
    String,
    Bool,
    Null,

    pub fn fromString(type_str: []const u8) ?Type {
        if (std.mem.eql(u8, type_str, "int")) return Type.Int;
        if (std.mem.eql(u8, type_str, "string")) return Type.String;
        if (std.mem.eql(u8, type_str, "bool")) return Type.Bool;
        if (std.mem.eql(u8, type_str, "null")) return Type.Null;
        return null;
    }

    pub fn toString(self: Type) []const u8 {
        return switch (self) {
            .Int => "int",
            .String => "string",
            .Bool => "bool",
            .Null => "null",
        };
    }
};

pub const TypeChecker = struct {
    allocator: std.mem.Allocator,
    environment: std.StringHashMap(Type),
    functions: std.StringHashMap(Function),

    pub fn init(allocator: std.mem.Allocator) TypeChecker {
        return TypeChecker{
            .allocator = allocator,
            .environment = std.StringHashMap(Type).init(allocator),
            .functions = std.StringHashMap(Function).init(allocator),
        };
    }

    pub fn deinit(self: *TypeChecker) void {
        self.environment.deinit();
        self.functions.deinit();
    }

    pub fn inferExprType(self: *TypeChecker, expr: *const ast.Expr) InferTypeResult {
        switch (expr.*) {
            .int_literal => return InferTypeResult{ .ok = Type.Int },
            .string_literal => return InferTypeResult{ .ok = Type.String },
            .bool_literal => return InferTypeResult{ .ok = Type.Bool },
            .identifier => |ident| {
                if (self.environment.get(ident.name)) |ident_type| {
                    return InferTypeResult{ .ok = ident_type };
                }
                return InferTypeResult{ .err = TypeError{ .kind = TypeCheckerError.UndefinedVariable, .name = ident.name } };
            },
            .binary => |bin| {
                const left_result = self.inferExprType(bin.left);
                const right_result = self.inferExprType(bin.right);
                const left_type = switch (left_result) {
                    .ok => |t| t,
                    .err => |err| return InferTypeResult{ .err = err },
                };
                const right_type = switch (right_result) {
                    .ok => |t| t,
                    .err => |err| return InferTypeResult{ .err = err },
                };
                if (left_type != right_type) {
                    return InferTypeResult{ .err = TypeError{ .kind = TypeCheckerError.TypeMismatch, .expected_type = left_type, .actual_type = right_type } };
                }

                const is_comparison = switch (bin.operator) {
                    .DoubleEqual, .NotEqual, .GreaterThan, .LessThan, .GreaterThanEqual, .LessThanEqual => true,
                    else => false,
                };

                if (is_comparison) {
                    return InferTypeResult{ .ok = Type.Bool };
                }

                return InferTypeResult{ .ok = left_type };
            },
            .assignment => |assign| {
                const value_infer_result = self.inferExprType(assign.value);
                const value_type = switch (value_infer_result) {
                    .ok => |t| t,
                    .err => |err| return InferTypeResult{ .err = err },
                };
                if (self.environment.get(assign.name)) |assign_type| {
                    if (assign_type != value_type) {
                        return InferTypeResult{ .err = TypeError{ .kind = TypeCheckerError.TypeMismatch, .expected_type = assign_type, .actual_type = value_type } };
                    }
                } else {
                    return InferTypeResult{ .err = TypeError{ .kind = TypeCheckerError.UndefinedVariable, .name = assign.name } };
                }
                return InferTypeResult{ .ok = value_type };
            },
            .call => |call| {
                if (!self.functions.contains(call.name)) {
                    return InferTypeResult{ .err = TypeError{ .kind = TypeCheckerError.UndefinedFunction, .name = call.name } };
                }

                const function = self.functions.getPtr(call.name).?;
                if (function.parameters.len != call.arguments.len) {
                    return InferTypeResult{ .err = TypeError{ .kind = TypeCheckerError.ArgumentCountMismatch } };
                }

                for (function.parameters, call.arguments) |param, arg| {
                    const arg_infer_result = self.inferExprType(arg);
                    const arg_type = switch (arg_infer_result) {
                        .ok => |t| t,
                        .err => |err| return InferTypeResult{ .err = err },
                    };
                    if (param.type_annotation) |param_type_str| {
                        if (Type.fromString(param_type_str)) |param_type| {
                            if (param_type != arg_type) {
                                return InferTypeResult{ .err = TypeError{ .kind = TypeCheckerError.TypeMismatch, .expected_type = param_type, .actual_type = arg_type } };
                            }
                            // return InferTypeResult{ .ok = param_type };
                        } else {
                            return InferTypeResult{ .err = TypeError{ .kind = TypeCheckerError.InvalidType, .message = param_type_str } };
                        }
                    } else {
                        return InferTypeResult{ .err = TypeError{ .kind = TypeCheckerError.InvalidType } };
                    }
                }

                if (function.return_type) |return_type_str| {
                    if (Type.fromString(return_type_str)) |return_type| {
                        return InferTypeResult{ .ok = return_type };
                    } else {
                        return InferTypeResult{ .err = TypeError{ .kind = TypeCheckerError.InvalidType } };
                    }
                } else {
                    return InferTypeResult{ .ok = Type.Null };
                }
            },
        }
    }

    pub fn checkStmt(self: *TypeChecker, stmt: *ast.Stmt, expected_return_type: ?Type) TypeCheckerResult {
        switch (stmt.*) {
            .const_decl => |const_decl| {
                const value_infer_result = self.inferExprType(&const_decl.value);
                const value_type = switch (value_infer_result) {
                    .ok => |t| t,
                    .err => |err| return TypeCheckerResult{ .err = err },
                };

                if (const_decl.type_annotation) |type_annotation_str| {
                    if (Type.fromString(type_annotation_str)) |expected_type| {
                        if (expected_type != value_type) {
                            return TypeCheckerResult{ .err = TypeError{ .kind = TypeCheckerError.TypeMismatch, .expected_type = expected_type, .actual_type = value_type } };
                        }
                        // return TypeCheckerResult.ok;
                    } else {
                        return TypeCheckerResult{ .err = TypeError{ .kind = TypeCheckerError.InvalidType, .message = type_annotation_str } };
                    }
                }

                if (self.environment.contains(const_decl.name)) {
                    return TypeCheckerResult{ .err = TypeError{ .kind = TypeCheckerError.VariableAlreadyDeclared, .name = const_decl.name } };
                }

                self.environment.put(const_decl.name, value_type) catch {
                    return TypeCheckerResult{ .err = TypeError{ .kind = TypeCheckerError.OutOfMemory } };
                };
                return TypeCheckerResult.ok;
            },
            .var_decl => |var_decl| {
                const value_infer_result = self.inferExprType(&var_decl.value);
                const value_type = switch (value_infer_result) {
                    .ok => |t| t,
                    .err => |err| return TypeCheckerResult{ .err = err },
                };

                if (var_decl.type_annotation) |type_annotation_str| {
                    if (Type.fromString(type_annotation_str)) |expected_type| {
                        if (expected_type != value_type) {
                            return TypeCheckerResult{ .err = TypeError{ .kind = TypeCheckerError.TypeMismatch, .expected_type = expected_type, .actual_type = value_type } };
                        }
                        // return TypeCheckerResult.ok;
                    } else {
                        return TypeCheckerResult{ .err = TypeError{ .kind = TypeCheckerError.InvalidType, .message = type_annotation_str } };
                    }
                }

                if (self.environment.contains(var_decl.name)) {
                    return TypeCheckerResult{ .err = TypeError{ .kind = TypeCheckerError.VariableAlreadyDeclared, .name = var_decl.name } };
                }

                self.environment.put(var_decl.name, value_type) catch {
                    return TypeCheckerResult{ .err = TypeError{ .kind = TypeCheckerError.OutOfMemory } };
                };
                return TypeCheckerResult.ok;
            },
            .expr_stmt => |expr_stmt| {
                const expr_infer_result = self.inferExprType(&expr_stmt.expr);
                switch (expr_infer_result) {
                    .ok => return TypeCheckerResult.ok,
                    .err => |err| return TypeCheckerResult{ .err = err },
                }
            },
            .return_stmt => |return_stmt| {
                if (expected_return_type) |expected_return| {
                    if (return_stmt.value) |value| {
                        const value_ptr = value;
                        const value_infer_result = self.inferExprType(&value_ptr);
                        const value_type = switch (value_infer_result) {
                            .ok => |t| t,
                            .err => |err| return TypeCheckerResult{ .err = err },
                        };
                        if (value_type != expected_return) {
                            return TypeCheckerResult{ .err = TypeError{ .kind = TypeCheckerError.TypeMismatch, .expected_type = expected_return, .actual_type = value_type } };
                        }
                        return TypeCheckerResult.ok;
                    } else {
                        // return with no value
                        if (expected_return != Type.Null) {
                            return TypeCheckerResult{ .err = TypeError{ .kind = TypeCheckerError.TypeMismatch, .expected_type = expected_return, .actual_type = Type.Null } };
                        }
                        return TypeCheckerResult.ok;
                    }
                } else {
                    // return statement outside a func
                    return TypeCheckerResult{ .err = TypeError{ .kind = TypeCheckerError.UnexpectedReturnOutsideFunction } };
                }
            },
            .func_decl => |func_decl| {
                if (self.functions.contains(func_decl.name)) {
                    return TypeCheckerResult{ .err = TypeError{ .kind = TypeCheckerError.FunctionAlreadyDeclared, .name = func_decl.name } };
                }

                var return_type: ?Type = null;
                if (func_decl.return_type) |return_type_str| {
                    if (Type.fromString(return_type_str)) |rt| {
                        return_type = rt;
                    } else {
                        return TypeCheckerResult{ .err = TypeError{ .kind = TypeCheckerError.InvalidType, .message = return_type_str } };
                    }
                } else {
                    return_type = Type.Null; // no return type means return null / void
                }

                // save env
                const old_env = self.environment;

                // create new env
                var func_env = std.StringHashMap(Type).init(self.allocator);
                defer func_env.deinit();

                for (func_decl.parameters) |param| {
                    if (param.type_annotation) |param_type_str| {
                        if (Type.fromString(param_type_str)) |param_type| {
                            if (func_env.contains(param.name)) {
                                return TypeCheckerResult{ .err = TypeError{ .kind = TypeCheckerError.VariableAlreadyDeclared, .name = param.name } };
                            }
                            func_env.put(param.name, param_type) catch {
                                return TypeCheckerResult{ .err = TypeError{ .kind = TypeCheckerError.OutOfMemory } };
                            };
                        } else {
                            return TypeCheckerResult{ .err = TypeError{ .kind = TypeCheckerError.InvalidType, .message = param_type_str } };
                        }
                    } else {
                        return TypeCheckerResult{ .err = TypeError{ .kind = TypeCheckerError.InvalidType } };
                    }
                }

                self.environment = func_env;

                for (func_decl.body) |body_stmt| {
                    const check_result = self.checkStmt(body_stmt, return_type);
                    switch (check_result) {
                        .ok => {},
                        .err => |err| return TypeCheckerResult{ .err = err },
                    }
                }

                self.environment = old_env;

                self.functions.put(func_decl.name, Function{
                    .parameters = func_decl.parameters,
                    .return_type = func_decl.return_type,
                    .body = func_decl.body,
                }) catch {
                    return TypeCheckerResult{ .err = TypeError{ .kind = TypeCheckerError.OutOfMemory } };
                };
                return TypeCheckerResult.ok;
            },
            .if_stmt => |if_stmt| {
                const condition_infer_result = self.inferExprType(&if_stmt.condition);
                const condition_type = switch (condition_infer_result) {
                    .ok => |t| t,
                    .err => |err| return TypeCheckerResult{ .err = err },
                };
                if (condition_type != Type.Bool) {
                    return TypeCheckerResult{ .err = TypeError{ .kind = TypeCheckerError.TypeMismatch, .expected_type = Type.Bool, .actual_type = condition_type } }; // Condition must be boolean
                }

                // Check then branch
                for (if_stmt.then_branch) |then_stmt| {
                    const check_result = self.checkStmt(then_stmt, expected_return_type);
                    switch (check_result) {
                        .ok => {},
                        .err => |err| return TypeCheckerResult{ .err = err },
                    }
                }

                // Check else branch if it exists
                if (if_stmt.else_branch) |else_branch| {
                    for (else_branch) |else_stmt| {
                        const check_result = self.checkStmt(else_stmt, expected_return_type);
                        switch (check_result) {
                            .ok => {},
                            .err => |err| return TypeCheckerResult{ .err = err },
                        }
                    }
                }
                return TypeCheckerResult.ok;
            },
        }
    }
};

pub const TypeError = struct {
    kind: TypeCheckerError,
    expected_type: ?Type = null,
    actual_type: ?Type = null,
    name: ?[]const u8 = null,
    message: ?[]const u8 = null,

    pub fn format(self: TypeError, allocator: std.mem.Allocator) ![]const u8 {
        switch (self.kind) {
            TypeCheckerError.TypeMismatch => {
                if (self.expected_type) |expected_type| {
                    if (self.actual_type) |actual_type| {
                        if (self.name) |name| {
                            return try std.fmt.allocPrint(allocator, "Type mismatch for '{s}': expected '{s}', got '{s}'", .{ name, expected_type.toString(), actual_type.toString() });
                        } else {
                            return try std.fmt.allocPrint(allocator, "Type mismatch: expected '{s}', got '{s}'", .{ expected_type.toString(), actual_type.toString() });
                        }
                    }
                }
                return try std.fmt.allocPrint(allocator, "Type mismatch", .{});
            },
            TypeCheckerError.UndefinedVariable => {
                if (self.name) |name| {
                    return try std.fmt.allocPrint(allocator, "Undefined variable: '{s}'", .{name});
                }
                return try std.fmt.allocPrint(allocator, "Undefined variable", .{});
            },
            TypeCheckerError.UndefinedFunction => {
                if (self.name) |name| {
                    return try std.fmt.allocPrint(allocator, "Undefined function: '{s}'", .{name});
                }
                return try std.fmt.allocPrint(allocator, "Undefined function", .{});
            },
            TypeCheckerError.ArgumentCountMismatch => {
                return try std.fmt.allocPrint(allocator, "Wrong number of arguments", .{});
            },
            TypeCheckerError.VariableAlreadyDeclared => {
                if (self.name) |name| {
                    return try std.fmt.allocPrint(allocator, "Variable '{s}' already declared", .{name});
                }
                return try std.fmt.allocPrint(allocator, "Variable already declared", .{});
            },
            TypeCheckerError.FunctionAlreadyDeclared => {
                if (self.name) |name| {
                    return try std.fmt.allocPrint(allocator, "Function '{s}' already declared", .{name});
                }
                return try std.fmt.allocPrint(allocator, "Function already declared", .{});
            },
            TypeCheckerError.InvalidType => {
                if (self.message) |msg| {
                    return try std.fmt.allocPrint(allocator, "Invalid type: {s}", .{msg});
                }
                return try std.fmt.allocPrint(allocator, "Invalid type", .{});
            },
            TypeCheckerError.UnexpectedReturnOutsideFunction => {
                return try std.fmt.allocPrint(allocator, "Unexpected return outside function", .{});
            },
            else => return try std.fmt.allocPrint(allocator, "Unknown type error", .{}),
        }
    }
};

pub const TypeCheckerResult = union(enum) {
    ok: void, // success
    err: TypeError, // error
};

pub const InferTypeResult = union(enum) {
    ok: Type, // Success case - carries the Type
    err: TypeError, // Error case
};
