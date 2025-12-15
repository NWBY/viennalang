const std = @import("std");
const Lexer = @import("../lexer/lexer.zig").Lexer;
const Token = @import("../lexer/token.zig").Token;
const TokenType = @import("../lexer/token.zig").TokenType;
const ast = @import("ast.zig");

pub const Parser = struct {
    lexer: *Lexer,
    current_token: Token,
    peek_token: Token,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, lexer: *Lexer) Parser {
        var parser = Parser{
            .lexer = lexer,
            .current_token = undefined,
            .peek_token = undefined,
            .allocator = allocator,
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

    fn currentTokenIs(self: *Parser, token_type: TokenType) bool {
        return self.current_token.type == token_type;
    }

    fn peekTokenIs(self: *Parser, token_type: TokenType) bool {
        return self.peek_token.type == token_type;
    }

    // Parse entry point
    pub fn parseExpression(self: *Parser) !*ast.Expr {
        return try self.parsePrimaryExpression();
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
                std.debug.print("Unexpected token: {s}\n", .{@tagName(self.current_token.type)});
                return error.UnexpectedToken;
            },
        }
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
};
