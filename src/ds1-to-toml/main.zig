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
        debug.print("cd /d '{s}'\n", .{resulted_cwd});
        assert(mem.eql(u8, mem.trimRight(u8, args[1], "\\"), resulted_cwd));
    }

    var tiles = dt1.tile.Hash{ .table = dt1.tile.Hash.Table.init(allocator) };
    defer tiles.table.deinit();
    try tiles.table.ensureTotalCapacity(1024);
    inline for (.{ "Crypt\\Basewall.dt1", "Crypt\\Floor.dt1" }) |filepath_tail|
        try tiles.loadAdd("data\\global\\tiles\\ACT1\\" ++ filepath_tail);

    var l_ps: [2]ds1.LevelPreset = undefined;
    inline for (&l_ps, .{ "Crypt\\cryptcountess1.ds1", "Crypt\\cryptcountess2.ds1" }) |*lp, filepath_tail|
        lp.* = try ds1.LevelPreset.init(
            allocator,
            tiles.table,
            "data\\global\\tiles\\ACT1\\" ++ filepath_tail,
        );
    defer for (&l_ps) |*lp| lp.deinit(allocator);

    var br = io.bufferedWriter(io.getStdOut().writer());
    defer br.flush() catch |err| debug.print("{}\n", .{err});
    const stdout = br.writer();
    for (&l_ps) |*lp| {
        try stdout.print(
            "[[level_preset]]\nname = \"{s}\"\ncolumns = {}\ndesc = [\n",
            .{ lp.name, lp.columns },
        );
        for (lp.desc) |row| try stdout.print("    \"{s}\",\n", .{row});
        try stdout.print("]\n\n", .{});
    }
}

const assert = debug.assert;
const debug = std.debug;
const ds1 = @import("ds1.zig");
const dt1 = @import("dt1.zig");
const heap = std.heap;
const io = std.io;
const mem = std.mem;
const process = std.process;
const std = @import("std");
