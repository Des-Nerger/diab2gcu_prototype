//! -lobals

pub var mouse: game.Position = undefined;
pub var cam: game.Position = undefined;
pub var pl: game.Entity = undefined;
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
    pub var list: std.ArrayList(*const game.Tile) = undefined;
    pub var width: c_int = undefined;
    pub var height: c_int = undefined;
    pub fn tile(y: c_int, x: c_int) meta.Child(@TypeOf(list.items)) {
        if (0 > y or y >= g.map.height or 0 > x or x >= g.map.width) return &game.Tile.out_of_map;
        return map.list.items[@intCast(y * map.width + x)];
    }
    pub fn draw() void {
        var dy: c_int = 0;
        while (dy < g.stdscr.height) : (dy += 1) {
            var dx: c_int = 0;
            while (dx < g.stdscr.width) : (dx += 1) {
                const y, const x = .{ g.cam.y + dy, g.cam.x + dx };
                assert(c.OK == c.mvaddch(dy, dx, @intCast(g.map.tile(y, x).wchar)) or
                    (dx == g.stdscr.width - 1 and dy == g.stdscr.height - 1));
            }
        }
    }
};
pub const stdscr = struct {
    pub var width: c_int = undefined;
    pub var height: c_int = undefined;
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
