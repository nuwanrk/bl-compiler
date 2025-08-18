const std = @import("std");
const parseInt = std.fmt.parseInt;
const testAllocator = std.testing.allocator;

const lexer = @import("lexer.zig");

pub fn main() !void {
    var debugAllocator = std.heap.DebugAllocator(.{
        .stack_trace_frames = 16,
    }).init;
    defer _ = debugAllocator.deinit();

    const gpa = debugAllocator.allocator();

    const args = try parseArgs();
    try run(gpa, args);
}

pub fn run(allocator: std.mem.Allocator, args: Args) !void {
    const path = args.path;
    const assembler_file, const exe = try objectPaths(allocator, path);
    defer {
        allocator.free(assembler_file);
        allocator.free(exe);
    }

    {
        // compiler
        const src = try std.fs.cwd().readFileAllocOptions(
            allocator,
            path,
            std.math.maxInt(usize),
            null,
            @alignOf(u8),
            0,
        );
        defer allocator.free(src);

        var l = lexer.Lexer.init(src);
        while (l.next()) |token| {
            std.debug.print("{?}: {s}\n", .{
                token.tag,
                src[token.loc.start..token.loc.end],
            });

            switch (token.tag) {
                .invalid => return error.LexerError,
                .eof => break,
                else => {},
            }
        }

        if (args.mode == .lex) return;
    }

    {
        // assembler
        var child = std.process.Child.init(
            &.{ "clang", assembler_file, "-o", exe },
            allocator,
        );
        defer std.fs.cwd().deleteFile(assembler_file) catch {};

        const status = try child.spawnAndWait();
        if (!std.meta.eql(status, .{ .Exited = 0 }))
            return error.AssemblerFail;
    }
}

const Args = struct {
    path: []const u8,
    mode: Mode,
};

const Mode = enum {
    lex,
    parse,
    codegen,
    compile,
    assembly,
};

fn objectPaths(allocator: std.mem.Allocator, path: []const u8) !struct {
    []const u8,
    []const u8,
} {
    const exe = try std.fs.path.join(
        allocator,
        &.{
            std.fs.path.dirname(path) orelse "",
            std.fs.path.stem(path),
        },
    );
    errdefer allocator.free(exe);

    const @"asm" = try std.mem.join(
        allocator,
        ".",
        &.{ exe, "s" },
    );

    return .{ @"asm", exe };
}

fn parseArgs() !Args {
    // example: zig build run -- lex assets/func1.bal
    var args = std.process.args();
    _ = args.skip(); // skip program name

    var path: []const u8 = "";
    var mode: Mode = .compile;

    var index: u8 = 0;
    while (args.next()) |arg| {
        if (index > 1) {
            return error.InvalidArguments;
        } else if (index == 0) {
            mode = std.meta.stringToEnum(Mode, arg[0..]) orelse
                return error.UnrecognizedFlag;
        } else {
            path = arg;
        }
        index += 1;
    }

    return .{ .path = path, .mode = mode };
}
