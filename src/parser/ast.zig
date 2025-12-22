const std = @import("std");

// Expression types
pub const Expr = union(enum) {
    int_literal: IntLiteral,
    string_literal: StringLiteral,
    bool_literal: BoolLiteral,
    identifier: Identifier,
    binary: BinaryExpr,
    assignment: AssignExpr,
    call: CallExpr,
};

pub const IntLiteral = struct {
    value: i64,
};

pub const StringLiteral = struct {
    value: []const u8,
};

pub const BoolLiteral = struct {
    value: bool,
};

pub const Identifier = struct {
    name: []const u8,
};

pub const BinaryExpr = struct {
    left: *Expr,
    operator: BinaryOp,
    right: *Expr,
};

pub const BinaryOp = enum {
    Add,
    Subtract,
    Multiply,
    Divide,
    DoubleEqual,
    NotEqual,
    GreaterThan,
    LessThan,
    GreaterThanEqual,
    LessThanEqual,
};

pub const AssignExpr = struct {
    name: []const u8,
    value: *Expr,
};

// Statement types
pub const Stmt = union(enum) {
    const_decl: ConstDecl,
    var_decl: VarDecl,
    return_stmt: ReturnStmt,
    expr_stmt: ExprStmt,
    func_decl: FuncDecl,
    if_stmt: IfStmt,
};

pub const ConstDecl = struct {
    name: []const u8,
    type_annotation: ?[]const u8,
    value: Expr,
};

pub const VarDecl = struct {
    name: []const u8,
    type_annotation: ?[]const u8,
    value: Expr,
};

pub const ReturnStmt = struct {
    value: ?Expr,
};

pub const ExprStmt = struct {
    expr: Expr,
};

pub const FuncDecl = struct {
    name: []const u8,
    return_type: ?[]const u8,
    parameters: []const Parameter,
    body: []*Stmt,
};

pub const IfStmt = struct {
    condition: Expr,
    then_branch: []*Stmt,
    else_branch: ?[]*Stmt,
};

pub const Parameter = struct {
    name: []const u8,
    type_annotation: ?[]const u8,
};

pub const CallExpr = struct {
    name: []const u8,
    arguments: []*Expr,
};
