const std = @import("std");
const parseInt = std.fmt.parseInt;

pub fn main() !void {
    std.debug.print("zig,{s}\n", .{"tool development"});
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
