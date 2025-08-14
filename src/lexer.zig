const std = @import("std");
const testAllocator = std.testing.allocator;

pub fn readfile(name: []const u8, alloc: std.mem.Allocator) ![]const u8 {
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
