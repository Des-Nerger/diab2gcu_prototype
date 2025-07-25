pub fn main() !void {
    var heap_debug = heap.DebugAllocator(.{}).init;
    defer _ = heap_debug.deinit();
    g.allocator = heap_debug.allocator();
    defer g.allocator = undefined;

    _ = d2moo.Drlg.init(.I, .normal, 42, .crypt);

    try Map.init();
    defer Map.deinit();

    gcu.init();
    defer gcu.deinit();

    game.init();
    defer game.deinit();
    game.loop();
}

const Map = @import("Map.zig");
const d2moo = @import("d2moo.zig");
const g = @import("g.zig");
const game = @import("game.zig");
const gcu = @import("gcu.zig");
const heap = std.heap;
const std = @import("std");
