const std = @import("std");
const parseInt = std.fmt.parseInt;
const testAllocator = std.testing.allocator;

pub fn main() !void {
    std.debug.print("zig,{s}\n", .{"tool development"});
}

fn readfile(name: []const u8, alloc: std.mem.Allocator) ![]const u8 {
    const file = try std.fs.cwd().openFile(name, .{});
    defer file.close();

    const stat = try file.stat();
    const size = stat.size;
    return try file.reader().readAllAlloc(alloc, size);
}

test "readfile" {
    const s = "assets/func1.bal";
    const content = try readfile(s, testAllocator);
    defer testAllocator.free(content);
    std.debug.print("{s}\n", .{content});
}

test "lexer" {
    const input = "123 67 89, 99";
    const gpa = std.testing.allocator;

    var list = std.ArrayList(u32).init(gpa);
    defer list.deinit();

    var it = std.mem.tokenizeAny(u8, input, " ,");
    while (it.next()) |num| {
        const n = try parseInt(u32, num, 10);
        try list.append(n);
    }

    const expected = [_]u32{ 123, 67, 89, 99 };
    for (expected, list.items) |exp, actual| {
        try std.testing.expectEqual(exp, actual);
    }

    std.debug.print("test passed\n", .{});
}
