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

        pub fn lexeme(tag: Tag) ?[]const u8 {
            return switch (tag) {
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
};

test "test func" {
    _ = "function ten() returns int { return 10; }";
}
