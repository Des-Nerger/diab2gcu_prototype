//! -lobals

pub var mouse: game.Position = undefined;
pub var cam: game.Position = undefined;
pub var pl: game.Entity = undefined;
pub var ent_path: game.Entity.Path = undefined;
pub var allocator: mem.Allocator = undefined;
pub const if_xterm = struct {
    pub var is: bool = undefined;

    /// If a terminal is of xterm-flavour,
    pub fn detectIs() void {
        @This().is = blk: {
            if (@import("builtin").os.tag == .windows) break :blk false;
            const term_env_val = process.getEnvVarOwned(g.allocator, "TERM") catch break :blk false;
            defer g.allocator.free(term_env_val);
            break :blk ascii.startsWithIgnoreCase(term_env_val, "xterm");
        };
    }

    /// , then enable / disables the terminal report mouse movement events.
    pub fn thenSetAnyEventMouse(comptime enable: bool) void {
        if (!@This().is) return;
        const esc_seq: [:0]const u8 = "\x1b[?1003" ++ (if (enable) "high" else "low")[0..1] ++ "\n";
        assert(esc_seq.len == c.printf(esc_seq));
    }
};
pub const map = struct {
    pub var tiles: []*const game.Tile = undefined;
    pub var width: c_int = undefined;

    pub fn tile(y: c_int, x: c_int) meta.Child(@TypeOf(tiles)) {
        var idx: usize = undefined;
        return if (0 > x or x >= g.map.width or blk: {
            idx = @intCast(y * map.width + x);
            break :blk 0 > idx or idx >= map.tiles.len;
        })
            &game.Tile.out_of_map
        else
            map.tiles[idx];
    }

    pub fn draw() void {
        var scr = game.Position{ .x = undefined, .y = 0 };
        while (scr.y < c.LINES) : (scr.y += 1) {
            scr.x = 0;
            while (scr.x < c.COLS) : (scr.x += 1) {
                const world = scr.toWorldPos();
                assert(c.OK == c.mvaddch(scr.y, scr.x, @intCast(g.map.tile(world.y, world.x).wchar)) or
                    (scr.x == c.COLS - 1 and scr.y == c.LINES - 1));
            }
        }
    }
};

const ascii = std.ascii;
const assert = debug.assert;
const c = @import("c.zig").c;
const debug = std.debug;
const g = @This();
const game = @import("game.zig");
const mem = std.mem;
const meta = std.meta;
const process = std.process;
const std = @import("std");
