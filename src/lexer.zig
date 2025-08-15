const std = @import("std");

const mem = std.mem;
const testing = std.testing;
const expect = testing.expect;
const pageAllocator = std.heap.page_allocator;


// https://github.com/ziglang/zig/blob/master/lib/std/zig/tokenizer.zig
pub const Token = struct {

    tag: Tag,
    loc: Loc, 

    // location within the source file for error reporting
    pub const Loc = struct {
        start: usize,
        end: useize,
    };

    pub const keywords = std.StaticStringMap(Tag).initComptime(.{
        .{"fuction", .keyword_function}
        .{"int", .type_int},
        .{"return", .keyword_return}, 
        .{"returns", .keyword_returns},

    }); 

    pub fn getKeyword(keyword:[]const u8) ?Tag {
        return keywords.get(keyword);
    }

    pub const Tag = enum {
        invalid, 
        identifier, 
        eof, 

        exclamation, // !

        l_paran,
        r_paran,
        l_brace,
        r_brace,
        semicolon,

        number_literal,

        // keywords
        type_int,
        keyword_function,
        keyword_main,
        keyword_returns,
        keyword_return, 

        pub fn lexem(tag:Tag) ?[]const u8 {
            return switch(tag) {
                .invalid,
                .identifier,
                .eof, 
                .number_literal,
                => null,

                .l_paran => "(",
                .r_paran => ")",
                .l_brace => "{",
                .r_brace => "}",

                .semicolon => ";",

                .type_int => "int",
                .keyword_function => "function",
                .keyword_main => "main",
                .keyword_return => "return",
                .keyword_returns => "returns",
            };
        }

        pub fn symbol(tag:Tag) []const u8 {
            return tag.lexem(tag) => orelse switch(tag) {
                .invalid => "invalid token",
                .identifier => "identifier", 
                .number_literal => "number",
                else => unreachable,
            };
        }
    };

    pub fn init(typ: TokenType, pos: usize, val: []const u8, line: usize) Token {
        return Token{ .typ = typ, .pos = pos, .val = val, .line = line };
    }

    pub fn print(self: Token) void {
        if (std.mem.eql(u8, self.val, "\n")) {
            std.debug.print("val = \\n", .{});
        } else {
            std.debug.print("val = {s}, ", .{self.val});
        }
        std.debug.print("type = {s}", .{self.typ.asstr()});
        std.debug.print("line = {d}\n", .{self.line});
    }
};

pub const LexerOptions = struct {
    print_tokens: bool,

    pub fn init(print_tokens: bool) LexerOptions {
        return LexerOptions{ .print_tokens = print_tokens };
    }
};

pub const Lexer = struct {
    input: []const u8, 
    start: usize, // start position of the token
    pos: usize, // current position of the input
    at_eof: bool, // end of the input and return eof
    options: LexerOptions, // config the lexer
    buffer: std.ArrayList(Token), // buffer to hold the tokens

    pub fn init(options: LexerOptions, input: []const u8) Lexer {
        const start_at = 0;
        const start_position = 0;
        const buf = std.ArrayList(Token).init(pageAllocator);

        return Lexer{ .input = input, .start = start_at, .pos = start_position, .at_eof = false, .options = options, .buffer = buf };
    }

    pub fn deinit(self: *Lexer) void {
        defer self.buffer.deinit();
    }

    pub fn print(self: *Lexer) void {
        for (self.buffer.items) |item| {
            item.print();
        }
    }

    pub fn size(self: *Lexer) usize {
        return self.buffer.items.len;
    }

    pub fn peek(self: *Lexer) u8 {
        if (self.pos + 1 < self.input.len) {
            return self.input[self.pos + 1];
        }
        return 0;
    }

    pub fn tokens(self: *Lexer) void {
        while (true) {
            const token: Token = self.next();
            self.buffer.append(token) catch @panic("out of memory occured");
            if (token.typ == TokenType.eof) {
                break;
            }
        }
    }

    fn next(self: *Lexer) Token {
        var line: u8 = 0;

        while (true) : (self.pos += 1) {
            if (self.pos == self.input.len) {
                self.at_eof = true;
                return Token.init(TokenType.eof, self.pos, "", line);
            }
            const ch = self.input[self.pos];
            if (ch == '\n') {
                line += 1;
                self.pos += 1;
                self.start = self.pos;
                return Token.init(TokenType.newline, self.pos, "\n", line);
            } else if (ch == ' ') { // skip white spaces
                self.pos += 1;
                self.start = self.pos;
            } else {
                if (self.pos + 1 < self.input.len) {
                    const next_ch:u8 = self.peek();
                }
                const identifier: []const u8 = self.input[self.start .. self.pos + 1];
                self.pos += 1;
                self.start = self.pos;
                return Token.init(TokenType.identifier, self.pos, identifier, line);
            }
        }
    }
};

test "test func" {
    const s = "function ten() returns int { return 10; }";

    const options = LexerOptions.init(true);
    var lexer = Lexer.init(options, s);
    lexer.tokens();

    lexer.print();
    //try expect(11 == lexer.size());
}
