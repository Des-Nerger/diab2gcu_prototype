pub fn main() !void {
    var heap_debug = heap.DebugAllocator(.{}).init;
    defer _ = heap_debug.deinit();
    const allocator = heap_debug.allocator();

    const args = try process.argsAlloc(allocator);
    defer process.argsFree(allocator, args);

    assert(0 == std.c.chdir(args[1])); // FIXME to posix.chdir
    {
        const resulted_cwd = try process.getCwdAlloc(allocator);
        defer allocator.free(resulted_cwd);
        debug.print("cd '{s}'\n", .{resulted_cwd});
        assert(mem.eql(u8, mem.trimRight(u8, args[1], "/\\"), resulted_cwd));
    }

    var bw = io.bufferedWriter(fs.File.stdout().deprecatedWriter());
    defer bw.flush() catch |err| debug.print("{}\n", .{err});
    const stdout = bw.writer();

    var tiles = dt1.tile.Hash{ .table = dt1.tile.Hash.Table.init(allocator) };
    defer tiles.table.deinit();
    try tiles.table.ensureTotalCapacity(1024);

    for (args[for (2.., args[2..]) |i, filepath| {
        if (!mem.eql(u8, ".dt1", fs.path.extension(filepath))) break i;
        tiles.loadAdd(filepath) catch |err| {
            debug.print("opening '{s}': ", .{filepath});
            return err;
        };
    } else unreachable..]) |ds1_filepath| {
        var lp = try ds1.LevelPreset.init(allocator, tiles.table, ds1_filepath);
        defer lp.deinit(allocator);
        try stdout.print("[[{s}]]\ncolumns = {}\ndesc = [\n", .{ lp.name, lp.columns });
        for (lp.desc) |row| try stdout.print("    \"{s}\",\n", .{row});
        try stdout.print("]\n\n", .{});
    }
}

const assert = debug.assert;
const debug = std.debug;
const ds1 = @import("ds1.zig");
const dt1 = @import("dt1.zig");
const fs = std.fs;
const heap = std.heap;
const io = std.io;
const mem = std.mem;
const process = std.process;
const std = @import("std");
