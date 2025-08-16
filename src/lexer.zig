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
        end: usize,
    };

    pub const keywords = std.StaticStringMap(Tag).initComptime(.{
        .{ "function", .keyword_function },
        .{ "int", .type_int },
        .{ "return", .keyword_return },
        .{ "returns", .keyword_returns },
    });

    pub fn getKeyword(keyword: []const u8) ?Tag {
        return keywords.get(keyword);
    }

    pub const Tag = enum {
        invalid,
        identifier,
        eof,

        exclamation, // !

        l_paren,
        r_paren,
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

        pub fn lexeme(tag: Tag) ?[]const u8 {
            return switch (tag) {
                .invalid,
                .identifier,
                .eof,
                .number_literal,
                => null,

                .l_paren => "(",
                .r_paren => ")",
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

        pub fn symbol(tag: Tag) []const u8 {
            return tag.lexeme(tag) orelse switch (tag) {
                .invalid => "invalid token",
                .identifier => "identifier",
                .number_literal => "number",
                else => unreachable,
            };
        }
    };
};

pub const Lexer = struct {
    buffer: [:0]const u8, // input source
    index: usize, // index in the source

    // for debugging purposes.
    pub fn dump(self: *Lexer, token: *const Token) void {
        std.debug.print("{s} \"{s}\"\n", .{ @tagName(token.Tag), self.buffer[token.loc.start..token.loc.end] });
    }

    pub fn init(buffer: [:0]const u8) Lexer {
        return .{
            .buffer = buffer,
            .index = if (std.mem.startsWith(u8, buffer, "\xEF\xBB\xBF")) 3 else 0, // skip UTF-8 BOM if present
        };
    }

    // token states
    const State = enum {
        start,
        identifier,
        int,
        invalid,
    };

    pub fn next(self: *Lexer) ?Token {
        var result: Token = .{
            .tag = undefined,
            .loc = .{
                .start = self.index,
                .end = undefined,
            },
        };

        state: switch (State.start) {
            .start => switch (self.buffer[self.index]) {
                0 => {
                    if (self.index == self.buffer.len) {
                        return .{
                            .tag = .eof,
                            .loc = .{
                                .start = self.index,
                                .end = self.index,
                            },
                        };
                    } else {
                        continue :state .invalid;
                    }
                },

                ' ', '\n', '\t', '\r' => { // skip whitespaces
                    self.index += 1;
                    result.loc.start = self.index;
                    continue :state .start;
                },
                'a'...'z', 'A'...'Z', '_' => {
                    result.tag = .identifier;
                    continue :state .identifier;
                },
                '0'...'9' => {
                    result.tag = .number_literal;
                    self.index += 1;
                    continue :state .int;
                },
                '(' => {
                    result.tag = .l_paren;
                    self.index += 1;
                },
                ')' => {
                    result.tag = .r_paren;
                    self.index += 1;
                },
                ';' => {
                    result.tag = .semicolon;
                    self.index += 1;
                },
                '{' => {
                    result.tag = .l_brace;
                    self.index += 1;
                },
                '}' => {
                    result.tag = .r_brace;
                    self.index += 1;
                },
                else => result.tag = .invalid,
            },

            .identifier => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    'a'...'z', 'A'...'Z', '_', '0'...'9' => continue :state .identifier,
                    else => {
                        const ident = self.buffer[result.loc.start..self.index];
                        if (Token.getKeyword(ident)) |tag| {
                            // found a keyword
                            result.tag = tag;
                        }
                    },
                }
            },
        }
    }
};

test "test func" {
    _ = "function ten() returns int { return 10; }";
}
