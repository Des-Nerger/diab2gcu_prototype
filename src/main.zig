const ArrayList = std.ArrayList;
// const c = @cImport({
//     @cInclude("curses.h");
// });
const debug = std.debug;
const heap = std.heap;
const io = std.io;
const json = std.json;
const mem = std.mem;
const std = @import("std");

pub fn main() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var jr = json.reader(allocator, io.getStdIn().reader());
    defer jr.deinit();

    const parsed = try json.parseFromTokenSource(Map, allocator, &jr, .{});
    defer parsed.deinit();

    const size = parsed.value.size;
    var map = try ArrayList(u8).initCapacity(allocator, size.width * size.height);
    defer map.deinit();
    for (parsed.value.map) |line| {
        var i: usize, var remaining = .{ 0, size.width };
        while (true) : (i += 1) {
            const run_len = if (i < line.len)
                line[i]
            else if (i == line.len)
                remaining
            else
                break;
            map.appendNTimesAssumeCapacity(if (i % 2 == 0) '#' else '.', run_len);
            remaining -= run_len;
        }
    }
    var lines = mem.window(u8, map.items, size.width, size.width);
    while (lines.next()) |line| {
        debug.print("{s}\n", .{line});
    }
}

const Map = struct {
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
};
