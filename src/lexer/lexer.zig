const std = @import("std");
const Token = @import("token.zig").Token;
const TokenType = @import("token.zig").TokenType;

pub const Lexer = struct {
    source: []const u8,
    current: usize,
    line: usize,
    column: usize,
    line_start: usize,

    pub fn init(source: []const u8) Lexer {
        return Lexer{
            .source = source,
            .current = 0,
            .line = 1,
            .column = 1,
            .line_start = 0,
        };
    }

    pub fn nextToken(self: *Lexer) Token {
        self.skipWhitespace();

        if (self.isAtEnd()) {
            return self.makeToken(TokenType.EOF);
        }

        const c = self.advance();

        // Single character tokens
        switch (c) {
            '(' => return self.makeToken(TokenType.LPAREN),
            ')' => return self.makeToken(TokenType.RPAREN),
            '{' => return self.makeToken(TokenType.LBRACE),
            '}' => return self.makeToken(TokenType.RBRACE),
            '+' => return self.makeToken(TokenType.PLUS),
            '-' => return self.makeToken(TokenType.MINUS),
            '*' => return self.makeToken(TokenType.STAR),
            '/' => return self.makeToken(TokenType.SLASH),
            ';' => return self.makeToken(TokenType.SEMICOLON),
            '=' => {
                if (self.peek() == '=') {
                    _ = self.advance();
                    return self.makeToken(TokenType.DOUBLE_EQUAL);
                }
                return self.makeToken(TokenType.ASSIGN);
            },
            ',' => return self.makeToken(TokenType.COMMA),
            ':' => return self.makeToken(TokenType.COLON),
            '>' => {
                if (self.peek() == '=') {
                    _ = self.advance();
                    return self.makeToken(TokenType.GREATER_THAN_EQUAL);
                }
                return self.makeToken(TokenType.GREATER_THAN);
            },
            '<' => {
                if (self.peek() == '=') {
                    _ = self.advance();
                    return self.makeToken(TokenType.LESS_THAN_EQUAL);
                }
                return self.makeToken(TokenType.LESS_THAN);
            },
            '!' => {
                if (self.peek() == '=') {
                    _ = self.advance();
                    return self.makeToken(TokenType.NOT_EQUAL);
                }
                return self.makeToken(TokenType.BANG);
            },
            else => {},
        }

        // Numbers
        if (std.ascii.isDigit(c)) {
            return self.number();
        }

        // Identifiers and keywords
        if (std.ascii.isAlphabetic(c)) {
            return self.identifier();
        }

        // Strings
        if (c == '"') {
            return self.string();
        }

        return self.errorToken("Unexpected character");
    }

    fn isAtEnd(self: *Lexer) bool {
        return self.current >= self.source.len;
    }

    fn advance(self: *Lexer) u8 {
        const c = self.source[self.current];
        self.current += 1;
        self.column += 1;
        return c;
    }

    fn peek(self: *Lexer) u8 {
        if (self.isAtEnd()) return 0;
        return self.source[self.current];
    }

    fn skipWhitespace(self: *Lexer) void {
        while (!self.isAtEnd()) {
            const c = self.peek();
            switch (c) {
                ' ', '\r', '\t' => {
                    _ = self.advance();
                },
                '\n' => {
                    self.line += 1;
                    self.column = 1;
                    self.line_start = self.current + 1;
                    _ = self.advance();
                },
                else => return,
            }
        }
    }

    fn number(self: *Lexer) Token {
        const start = self.current - 1;

        while (!self.isAtEnd() and std.ascii.isDigit(self.peek())) {
            _ = self.advance();
        }

        return Token{
            .type = TokenType.INT,
            .lexeme = self.source[start..self.current],
            .line = self.line,
            .column = self.column,
        };
    }

    fn string(self: *Lexer) Token {
        const start = self.current;

        while (!self.isAtEnd() and self.peek() != '"') {
            if (self.peek() == '\n') self.line += 1;
            _ = self.advance();
        }

        if (self.isAtEnd()) {
            return self.errorToken("Unterminated string");
        }

        _ = self.advance(); // closing "

        return Token{
            .type = TokenType.STRING,
            .lexeme = self.source[start .. self.current - 1],
            .line = self.line,
            .column = self.column,
        };
    }

    fn identifier(self: *Lexer) Token {
        const start = self.current - 1;

        while (!self.isAtEnd() and (std.ascii.isAlphanumeric(self.peek()) or self.peek() == '_')) {
            _ = self.advance();
        }

        const text = self.source[start..self.current];
        const tokenType = self.identifierType(text);

        return Token{
            .type = tokenType,
            .lexeme = text,
            .line = self.line,
            .column = self.column,
        };
    }

    fn identifierType(self: *Lexer, text: []const u8) TokenType {
        _ = self;

        // Check keywords
        if (std.mem.eql(u8, text, "const")) return TokenType.CONST;
        if (std.mem.eql(u8, text, "var")) return TokenType.VAR;
        if (std.mem.eql(u8, text, "func")) return TokenType.FUNC;
        if (std.mem.eql(u8, text, "return")) return TokenType.RETURN;
        if (std.mem.eql(u8, text, "if")) return TokenType.IF;
        if (std.mem.eql(u8, text, "else")) return TokenType.ELSE;
        if (std.mem.eql(u8, text, "true")) return TokenType.TRUE;
        if (std.mem.eql(u8, text, "false")) return TokenType.FALSE;

        return TokenType.IDENT;
    }

    fn makeToken(self: *Lexer, tokenType: TokenType) Token {
        return Token{
            .type = tokenType,
            .lexeme = self.source[self.current - 1 .. self.current],
            .line = self.line,
            .column = self.column - 1,
        };
    }

    fn errorToken(self: *Lexer, message: []const u8) Token {
        return Token{
            .type = TokenType.EOF, // TODO: make a proper error token type
            .lexeme = message,
            .line = self.line,
            .column = self.column - 1,
        };
    }

    pub fn getCurrentLine(self: *Lexer) []const u8 {
        var end = self.line_start;
        while (end < self.source.len and self.source[end] != '\n') {
            end += 1;
        }
        return self.source[self.line_start..end];
    }
};
