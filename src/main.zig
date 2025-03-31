pub fn main() !void {
    var heap_debug = heap.DebugAllocator(.{}).init;
    defer _ = heap_debug.deinit();
    g.allocator = heap_debug.allocator();
    defer g.allocator = undefined;

    try Map.init();
    defer Map.deinit();

    gcu.init();
    defer gcu.deinit();

    game.init();
    defer game.deinit();
    game.loop();
}

const Map = @import("Map.zig");
const g = @import("g.zig");
const game = @import("game.zig");
const gcu = @import("gcu.zig");
const heap = std.heap;
const std = @import("std");
