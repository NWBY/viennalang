const std = @import("std");
const ast = @import("../parser/ast.zig");
const Function = @import("interpreter.zig").Function;

pub const TypeCheckerError = error{
    UndefinedVariable,
    InvalidType,
    TypeMismatch,
    RecursiveType,
    InfiniteLoop,
    UnexpectedEOF,
    UnexpectedToken,
    UndefinedFunction,
    ArgumentCountMismatch,
};

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

    pub fn inferExprType(self: *TypeChecker, expr: *const ast.Expr) TypeCheckerError!Type {
        switch (expr.*) {
            .int_literal => return Type.Int,
            .string_literal => return Type.String,
            .bool_literal => return Type.Bool,
            .identifier => |ident| {
                if (self.environment.get(ident.name)) |ident_type| {
                    return ident_type;
                }
                return TypeCheckerError.UndefinedVariable;
            },
            .binary => |bin| {
                const left_type = try self.inferExprType(bin.left);
                const right_type = try self.inferExprType(bin.right);
                if (left_type != right_type) {
                    return TypeCheckerError.TypeMismatch;
                }

                const is_comparison = switch (bin.operator) {
                    .DoubleEqual, .NotEqual, .GreaterThan, .LessThan, .GreaterThanEqual, .LessThanEqual => true,
                    else => false,
                };

                if (is_comparison) {
                    return Type.Bool;
                }

                return left_type;
            },
            .assignment => |assign| {
                const value_type = try self.inferExprType(assign.value);
                if (self.environment.get(assign.name)) |assign_type| {
                    if (assign_type != value_type) {
                        return TypeCheckerError.TypeMismatch;
                    }
                } else {
                    return TypeCheckerError.UndefinedVariable;
                }
                return value_type;
            },
            .call => |call| {
                if (!self.functions.contains(call.name)) {
                    return TypeCheckerError.UndefinedFunction;
                }

                const function = self.functions.getPtr(call.name).?;
                if (function.parameters.len != call.arguments.len) {
                    return TypeCheckerError.ArgumentCountMismatch;
                }
                return function.return_type;
            },
        }
    }
};
