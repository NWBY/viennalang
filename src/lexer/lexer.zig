const std = @import("std");
const Token = @import("token.zig").Token;
const TokenType = @import("token.zig").TokenType;

pub const Lexer = struct {
    source: []const u8,
    current: usize,
    line: usize,

    pub fn init(source: []const u8) Lexer {
        return Lexer{
            .source = source,
            .current = 0,
            .line = 1,
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
            '=' => return self.makeToken(TokenType.ASSIGN),
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
        };
    }

    fn errorToken(self: *Lexer, message: []const u8) Token {
        return Token{
            .type = TokenType.EOF, // TODO: make a proper error token type
            .lexeme = message,
            .line = self.line,
        };
    }
};
