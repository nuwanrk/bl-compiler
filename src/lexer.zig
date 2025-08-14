const std = @import("std");

const mem = std.mem;
const testing = std.testing;
const expect = testing.expect;
const pageAllocator = std.heap.page_allocator;
const testAllocator = std.testing.allocator;

pub const TokenType = enum {
    err, // unknown token
    eof,
    identifier,
    val,
    newline,
    comment,

    fn asstr(self: TokenType) []const u8 {
        if (self == TokenType.err) {
            return "err";
        } else if (self == TokenType.eof) {
            return "eof";
        } else if (self == TokenType.identifier) {
            return "identifier";
        } else if (self == TokenType.val) {
            return "val";
        } else if (self == TokenType.newline) {
            return "newline";
        } else {
            return "unknown";
        }
    }
};

fn readfile(name: []const u8, alloc: std.mem.Allocator) ![]const u8 {
    const file = try std.fs.cwd().openFile(name, .{});
    defer file.close();

    const stat = try file.stat();
    const size = stat.size;
    return try file.reader().readAllAlloc(alloc, size);
}

test "readfile" {
    const s = "../assets/integers.bal";
    const content = try readfile(s, testAllocator);
    defer testAllocator.free(content);
    std.debug.print("{s}\n", .{content});
}
