const std = @import("std");
const Lexer = @import("../lexer/lexer.zig").Lexer;
const Token = @import("../lexer/token.zig").Token;
const TokenType = @import("../lexer/token.zig").TokenType;
const precedence_file = @import("precendence.zig");
const ViennaError = @import("../interpreter/error.zig").ViennaError;
const ast = @import("ast.zig");

pub const Parser = struct {
    lexer: *Lexer,
    current_token: Token,
    peek_token: Token,
    allocator: std.mem.Allocator,
    had_error: bool,

    pub fn init(allocator: std.mem.Allocator, lexer: *Lexer) Parser {
        var parser = Parser{
            .lexer = lexer,
            .current_token = undefined,
            .peek_token = undefined,
            .allocator = allocator,
            .had_error = false,
        };

        // Read two tokens so current_token and peek_token are both set
        parser.nextToken();
        parser.nextToken();

        return parser;
    }

    fn nextToken(self: *Parser) void {
        self.current_token = self.peek_token;
        self.peek_token = self.lexer.nextToken();
    }

    pub fn currentTokenIs(self: *Parser, token_type: TokenType) bool {
        return self.current_token.type == token_type;
    }

    fn peekTokenIs(self: *Parser, token_type: TokenType) bool {
        return self.peek_token.type == token_type;
    }

    fn reportError(self: *Parser, message: []const u8) void {
        self.had_error = true;

        const err = ViennaError{
            .message = message,
            .line = self.current_token.line,
            .column = self.current_token.column,
            .source_line = self.lexer.getCurrentLine(),
        };

        err.print();
    }

    // Parse entry point
    pub fn parseExpression(self: *Parser) !*ast.Expr {
        return try self.parseExpressionWithPrecedence(precedence_file.Precedence.LOWEST);
    }

    pub fn parseStatement(self: *Parser) !*ast.Stmt {
        switch (self.current_token.type) {
            TokenType.CONST => return try self.parseConstDeclaration(),
            else => {
                // 1. Parse expression
                const expr = try self.parseExpression();

                // 2. Check for semicolon
                if (self.currentTokenIs(TokenType.SEMICOLON)) {
                    self.nextToken(); // consume semicolon
                } else {
                    self.reportError("Expected ';' after expression");
                    return error.ExpectedSemicolon;
                }

                // 3. Create Stmt with expr_stmt
                const stmt = try self.allocator.create(ast.Stmt);
                stmt.* = ast.Stmt{
                    .expr_stmt = ast.ExprStmt{
                        .expr = expr.*,
                    },
                };

                return stmt;
            },
        }
    }

    // Parse primary expressions (literals)
    // Literals: int, string, bool
    // Will add more types later
    fn parsePrimaryExpression(self: *Parser) !*ast.Expr {
        switch (self.current_token.type) {
            TokenType.INT => return try self.parseIntegerLiteral(),
            TokenType.STRING => return try self.parseStringLiteral(),
            TokenType.TRUE, TokenType.FALSE => return try self.parseBooleanLiteral(),
            else => {
                self.reportError("Expected expression");
                return error.UnexpectedToken;
            },
        }
    }

    fn parseExpressionWithPrecedence(self: *Parser, precedence: precedence_file.Precedence) !*ast.Expr {
        // Parse left side (a number, identifier, etc.)
        var left = try self.parsePrimaryExpression();

        // While we have an operator with higher precedence
        while (@intFromEnum(precedence_file.getTokenPrecedence(self.current_token.type)) > @intFromEnum(precedence)) {
            const operator = self.current_token.type;
            const op_precedence = precedence_file.getTokenPrecedence(operator);

            self.nextToken(); // consume operator

            // Parse right side with higher precedence
            const right = try self.parseExpressionWithPrecedence(op_precedence);

            // Build binary expression
            const binary_expr = try self.allocator.create(ast.Expr);
            binary_expr.* = ast.Expr{
                .binary = ast.BinaryExpr{
                    .left = left,
                    .operator = tokenTypeToBinaryOp(operator),
                    .right = right,
                },
            };

            left = binary_expr;
        }

        return left;
    }

    fn parseIntegerLiteral(self: *Parser) !*ast.Expr {
        // Parse the string to an integer
        const value = try std.fmt.parseInt(i64, self.current_token.lexeme, 10);

        // Allocate memory for the expression node
        const expr = try self.allocator.create(ast.Expr);

        // Set the expression to be an integer literal
        expr.* = ast.Expr{
            .int_literal = ast.IntLiteral{
                .value = value,
            },
        };

        // Move to next token
        self.nextToken();

        return expr;
    }

    fn parseStringLiteral(self: *Parser) !*ast.Expr {
        const expr = try self.allocator.create(ast.Expr);

        expr.* = ast.Expr{
            .string_literal = ast.StringLiteral{
                .value = self.current_token.lexeme,
            },
        };

        self.nextToken();
        return expr;
    }

    fn parseBooleanLiteral(self: *Parser) !*ast.Expr {
        const value = self.currentTokenIs(TokenType.TRUE);

        const expr = try self.allocator.create(ast.Expr);

        expr.* = ast.Expr{
            .bool_literal = ast.BoolLiteral{
                .value = value,
            },
        };

        self.nextToken();
        return expr;
    }

    fn parseConstDeclaration(self: *Parser) !*ast.Stmt {
        self.nextToken(); // consume const

        const name = self.current_token.lexeme;

        self.nextToken(); // consume name
        if (!self.currentTokenIs(TokenType.ASSIGN)) {
            self.reportError("Expected '=' after constant name");
            return error.ExpectedEquals; // Report the error!
        }
        self.nextToken();

        const value = try self.parseExpression();

        const stmt = try self.allocator.create(ast.Stmt);

        if (!self.currentTokenIs(TokenType.SEMICOLON)) { // ✓ Check current
            self.reportError("Expected ';' after constant declaration");
            return error.ExpectedSemicolon;
        }
        self.nextToken();

        stmt.* = ast.Stmt{
            .const_decl = ast.ConstDecl{
                .name = name,
                .type_annotation = null,
                .value = value.*,
            },
        };
        return stmt;
    }
};

fn tokenTypeToBinaryOp(token_type: TokenType) ast.BinaryOp {
    return switch (token_type) {
        TokenType.PLUS => ast.BinaryOp.Add,
        TokenType.MINUS => ast.BinaryOp.Subtract,
        TokenType.STAR => ast.BinaryOp.Multiply,
        TokenType.SLASH => ast.BinaryOp.Divide,
        else => unreachable,
    };
}
