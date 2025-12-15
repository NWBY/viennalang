const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;
const TokenType = @import("token.zig").TokenType;

test "lexer tokenizes integers" {
    var lexer = Lexer.init("42");
    const token = lexer.nextToken();
    try std.testing.expectEqual(TokenType.INT, token.type);
    try std.testing.expectEqualStrings("42", token.lexeme);
}

test "lexer tokenizes operators" {
    var lexer = Lexer.init("+ - * /");

    var token = lexer.nextToken();
    try std.testing.expectEqual(TokenType.PLUS, token.type);

    token = lexer.nextToken();
    try std.testing.expectEqual(TokenType.MINUS, token.type);

    token = lexer.nextToken();
    try std.testing.expectEqual(TokenType.STAR, token.type);

    token = lexer.nextToken();
    try std.testing.expectEqual(TokenType.SLASH, token.type);
}

test "lexer tokenizes strings" {
    var lexer = Lexer.init("\"hello world\"");
    const token = lexer.nextToken();
    try std.testing.expectEqual(TokenType.STRING, token.type);
    try std.testing.expectEqualStrings("hello world", token.lexeme);
}

test "lexer tokenizes keywords" {
    var lexer = Lexer.init("const var func");

    var token = lexer.nextToken();
    try std.testing.expectEqual(TokenType.CONST, token.type);

    token = lexer.nextToken();
    try std.testing.expectEqual(TokenType.VAR, token.type);

    token = lexer.nextToken();
    try std.testing.expectEqual(TokenType.FUNC, token.type);
}

test "lexer tracks line numbers" {
    var lexer = Lexer.init("42\n100\n200");

    var token = lexer.nextToken();
    try std.testing.expectEqual(@as(usize, 1), token.line);

    token = lexer.nextToken();
    try std.testing.expectEqual(@as(usize, 2), token.line);

    token = lexer.nextToken();
    try std.testing.expectEqual(@as(usize, 3), token.line);
}
