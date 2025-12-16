const std = @import("std");
const Lexer = @import("../lexer/lexer.zig").Lexer;
const Token = @import("../lexer/token.zig").Token;
const TokenType = @import("../lexer/token.zig").TokenType;
const precedence_file = @import("precendence.zig");
const ViennaError = @import("../interpreter/error.zig").ViennaError;
const ast = @import("ast.zig");

const ParserError = error{ ExpectedAssignment, ExpectedSemicolon, ExpectedEquals, UnexpectedToken, ExpectedExpression, ExpectReturnType, OutOfMemory, Overflow, InvalidCharacter, ExpectedRightBrace, ExpectedLeftBrace, ExpectedLeftParen, ExpectedRightParen, ExpectedColon, ExpectedComma, ExpectedFuncDeclaration, ExpectedFuncParameters, ExpectedFuncReturnType, ExpectedFuncBody, ExpectedCommaOrRightParen };

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

    pub fn parseStatement(self: *Parser) ParserError!*ast.Stmt {
        switch (self.current_token.type) {
            TokenType.CONST => return try self.parseConstDeclaration(),
            TokenType.VAR => return try self.parseVarDeclaration(),
            TokenType.FUNC => return try self.parseFuncDeclaration(),
            TokenType.RETURN => return try self.parseReturnStatement(),
            else => {
                // 1. Parse expression
                const expr = try self.parseExpression();

                if (expr.* != .assignment) {
                    self.reportError("Expected assignment expression");
                    return ParserError.ExpectedAssignment;
                }

                // 2. Check for semicolon
                if (self.currentTokenIs(TokenType.SEMICOLON)) {
                    self.nextToken(); // consume semicolon
                } else {
                    self.reportError("Expected ';' after expression");
                    return ParserError.ExpectedSemicolon;
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
            TokenType.IDENT => return try self.parseIdentifier(),
            else => {
                self.reportError("Expected expression");
                return ParserError.UnexpectedToken;
            },
        }
    }

    fn parseExpressionWithPrecedence(self: *Parser, precedence: precedence_file.Precedence) !*ast.Expr {
        if (self.current_token.type == TokenType.IDENT and self.peekTokenIs(TokenType.ASSIGN)) {
            const name = self.current_token.lexeme;
            self.nextToken(); // consume identifier
            self.nextToken(); // consume assignment

            const value = try self.parseExpressionWithPrecedence(precedence_file.Precedence.LOWEST);
            const assign_expr = try self.allocator.create(ast.Expr);
            assign_expr.* = ast.Expr{
                .assignment = ast.AssignExpr{
                    .name = name,
                    .value = value,
                },
            };

            return assign_expr;
        }

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

    fn parseConstDeclaration(self: *Parser) ParserError!*ast.Stmt {
        self.nextToken(); // consume const

        const name = self.current_token.lexeme;

        self.nextToken(); // consume name
        if (!self.currentTokenIs(TokenType.ASSIGN)) {
            self.reportError("Expected '=' after constant name");
            return ParserError.ExpectedEquals; // Report the error!
        }
        self.nextToken();

        const value = try self.parseExpression();

        const stmt = try self.allocator.create(ast.Stmt);

        if (!self.currentTokenIs(TokenType.SEMICOLON)) { // ✓ Check current
            self.reportError("Expected ';' after constant declaration");
            return ParserError.ExpectedSemicolon;
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

    fn parseVarDeclaration(self: *Parser) ParserError!*ast.Stmt {
        self.nextToken(); // consume var

        const name = self.current_token.lexeme;

        self.nextToken(); // consume name
        if (!self.currentTokenIs(TokenType.ASSIGN)) {
            self.reportError("Expected '=' after variable name");
            return ParserError.ExpectedEquals; // Report the error!
        }
        self.nextToken();

        const value = try self.parseExpression();

        const stmt = try self.allocator.create(ast.Stmt);

        if (!self.currentTokenIs(TokenType.SEMICOLON)) { // ✓ Check current
            self.reportError("Expected ';' after variable declaration");
            return ParserError.ExpectedSemicolon;
        }
        self.nextToken();

        stmt.* = ast.Stmt{
            .var_decl = ast.VarDecl{
                .name = name,
                .type_annotation = null,
                .value = value.*,
            },
        };
        return stmt;
    }

    fn parseIdentifier(self: *Parser) !*ast.Expr {
        const name = self.current_token.lexeme;

        if (self.peekTokenIs(TokenType.LPAREN)) {
            self.nextToken(); // consume identifier
            return try self.parseFunctionCall(name);
        }

        const expr = try self.allocator.create(ast.Expr);

        expr.* = ast.Expr{
            .identifier = ast.Identifier{
                .name = name,
            },
        };

        self.nextToken();
        return expr;
    }

    fn parseFuncDeclaration(self: *Parser) ParserError!*ast.Stmt {
        self.nextToken(); // consume func

        const func_name = self.current_token.lexeme;
        self.nextToken(); // consume function name

        if (!self.currentTokenIs(TokenType.LPAREN)) {
            self.reportError("Expected '(' after function name");
            return ParserError.ExpectedLeftParen;
        }
        self.nextToken(); // consume left parenthesis

        const parameters = try self.parseParameters();

        if (!self.currentTokenIs(TokenType.RPAREN)) {
            self.reportError("Expected ')' after parameters");
            return ParserError.ExpectedRightParen;
        }
        self.nextToken(); // consume right parenthesis

        const return_type = try self.parseReturnType();

        if (!self.currentTokenIs(TokenType.LBRACE)) {
            self.reportError("Expected '{' after function parameters");
            return ParserError.ExpectedLeftBrace;
        }
        self.nextToken(); // consume left brace

        const body = try self.parseBlock();

        const stmt = try self.allocator.create(ast.Stmt);
        stmt.* = ast.Stmt{
            .func_decl = ast.FuncDecl{
                .name = func_name,
                .return_type = return_type,
                .parameters = parameters,
                .body = body,
            },
        };
        return stmt;
    }

    fn parseParameters(self: *Parser) ParserError![]ast.Parameter {
        var parameters = try std.ArrayList(ast.Parameter).initCapacity(self.allocator, 10);

        while (self.currentTokenIs(TokenType.IDENT)) {
            const param_name = self.current_token.lexeme;
            self.nextToken(); // consume parameter name

            if (!self.currentTokenIs(TokenType.COLON)) {
                self.reportError("Expected ':' after parameter name");
                return ParserError.ExpectedColon;
            }
            self.nextToken(); // consume colon

            const param_type = self.current_token.lexeme;
            self.nextToken(); // consume parameter type

            try parameters.append(self.allocator, ast.Parameter{
                .name = param_name,
                .type_annotation = param_type,
            });

            if (self.currentTokenIs(TokenType.RPAREN)) {
                break;
            }

            if (!self.currentTokenIs(TokenType.COMMA)) {
                self.reportError("Expected ',' after parameter");
                return ParserError.ExpectedComma;
            }
            self.nextToken(); // consume comma
        }

        return parameters.items;
    }

    fn parseReturnType(self: *Parser) ParserError!?[]const u8 {
        if (!self.currentTokenIs(TokenType.MINUS) or !self.peekTokenIs(TokenType.GREATER)) {
            return null;
        }
        self.nextToken(); // consume -
        self.nextToken(); // consume >

        const return_type = self.current_token.lexeme;
        self.nextToken(); // consume return type

        return return_type;
    }

    fn parseBlock(self: *Parser) ParserError![]*ast.Stmt {
        var statements = try std.ArrayList(*ast.Stmt).initCapacity(self.allocator, 10);

        while (!self.currentTokenIs(TokenType.RBRACE) and !self.currentTokenIs(TokenType.EOF)) {
            const stmt = try self.parseStatement();
            try statements.append(self.allocator, stmt);
        }

        if (!self.currentTokenIs(TokenType.RBRACE)) {
            self.reportError("Expected '}' after function body");
            return ParserError.ExpectedRightBrace;
        }
        self.nextToken(); // consume }

        return statements.items;
    }

    fn parseReturnStatement(self: *Parser) ParserError!*ast.Stmt {
        self.nextToken(); // consume return

        const stmt = try self.allocator.create(ast.Stmt);

        // Check if there's a return value
        if (self.currentTokenIs(TokenType.SEMICOLON)) {
            // No return value: return;
            stmt.* = ast.Stmt{
                .return_stmt = ast.ReturnStmt{
                    .value = null,
                },
            };
            self.nextToken(); // consume semicolon
        } else {
            // Has return value: return expr;
            const expr = try self.parseExpression();
            if (!self.currentTokenIs(TokenType.SEMICOLON)) {
                self.reportError("Expected ';' after return value");
                return ParserError.ExpectedSemicolon;
            }
            self.nextToken(); // consume semicolon

            stmt.* = ast.Stmt{
                .return_stmt = ast.ReturnStmt{
                    .value = expr.*,
                },
            };
        }

        return stmt;
    }

    fn parseFunctionCall(self: *Parser, name: []const u8) ParserError!*ast.Expr {
        const expr = try self.allocator.create(ast.Expr);
        expr.* = ast.Expr{
            .call = ast.CallExpr{
                .name = name,
                .arguments = try self.parseArguments(),
            },
        };
        return expr;
    }

    fn parseArguments(self: *Parser) ParserError![]*ast.Expr {
        var arguments = try std.ArrayList(*ast.Expr).initCapacity(self.allocator, 10);

        if (!self.currentTokenIs(TokenType.LPAREN)) {
            self.reportError("Expected '(' after function name");
            return ParserError.ExpectedLeftParen;
        }
        self.nextToken(); // consume left parenthesis

        while (!self.currentTokenIs(TokenType.RPAREN) and !self.currentTokenIs(TokenType.EOF)) {
            const arg = try self.parseExpression();
            try arguments.append(self.allocator, arg);

            if (self.currentTokenIs(TokenType.COMMA)) {
                self.nextToken(); // consume comma
            } else if (!self.currentTokenIs(TokenType.RPAREN)) {
                self.reportError("Expected ',' or ')' after argument");
                return ParserError.ExpectedCommaOrRightParen;
            }
        }

        if (!self.currentTokenIs(TokenType.RPAREN)) {
            self.reportError("Expected ')' after arguments");
            return ParserError.ExpectedRightParen;
        }
        self.nextToken(); // consume right parenthesis

        return arguments.items;
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
