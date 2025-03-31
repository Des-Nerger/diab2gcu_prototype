type: []u8,
id: i32,
name: []u8,
offset: struct {
    x: i32,
    y: i32,
},
size: struct {
    width: usize,
    height: usize,
},
objects: []struct {
    id: i32,
    type: []u8,
    x: i32,
    y: i32,
    name: ?[]u8 = null,
    op: ?i32 = null,
    class: ?[]u8 = null,
},
map: [][]usize,

pub fn deinit() void {
    g.map.list.deinit();
    g.pl, g.map.list, g.map.width, g.map.height = .{undefined} ** 4;
}

pub fn init() !void {
    const args = try process.argsAlloc(g.allocator);
    defer process.argsFree(g.allocator, args);

    const file = try fs.cwd().openFile(args[2], .{});
    defer file.close();

    var buf: [64 * 1024]u8 = undefined;

    var levelmap_jso_line: []u8 = &.{};
    while (true) {
        levelmap_jso_line = (try file.reader().readUntilDelimiterOrEof(buf[0..], '\n')).?;
        if (null != ascii.indexOfIgnoreCase(levelmap_jso_line, args[1])) break;
    }
    // debug.print("«{s}»\n", .{levelmap_jso_line});

    var levelmap_jso_fbs = io.fixedBufferStream(levelmap_jso_line);
    var jr = json.reader(g.allocator, levelmap_jso_fbs.reader());
    defer jr.deinit();

    const parsed = try json.parseFromTokenSource(Self, g.allocator, &jr, .{});
    defer parsed.deinit();

    // Never ever use `parsed.value.height`, it's wrong!
    g.map.width, g.map.height = .{ @intCast(parsed.value.size.width), @intCast(parsed.value.map.len) };
    g.map.list = try @TypeOf(g.map.list).initCapacity(g.allocator, @intCast(g.map.width * g.map.height));
    for (parsed.value.map) |line| {
        var i, var remaining = [_]usize{ 0, @intCast(g.map.width) };
        while (true) : (i += 1) {
            const run_len = if (i < line.len)
                line[i]
            else if (i == line.len)
                remaining
            else
                break;
            g.map.list.appendNTimesAssumeCapacity(&(if (i % 2 == 0)
                game.Tile.wall
            else
                game.Tile.floor), run_len);
            remaining -= run_len;
        }
    }

    // var lines = mem.window(u8, g.map.items, size.width, size.width);
    // while (lines.next()) |line| {
    //     debug.print("{s}\n", .{line});
    // }

    for (parsed.value.objects) |obj| {
        if (mem.eql(u8, "exit", obj.type)) {
            g.pl = player.init(.{ .x = obj.x + 1, .y = obj.y + 1 });
            return;
        }
    }
    unreachable;
}

const Self = @This();
const ascii = std.ascii;
const fs = std.fs;
const g = @import("g.zig");
const game = @import("game.zig");
const io = std.io;
const json = std.json;
const mem = std.mem;
const player = @import("player.zig");
const process = std.process;
const std = @import("std");
