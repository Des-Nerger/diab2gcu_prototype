pub const Position = struct {
    y: c_int,
    x: c_int,
};

pub const Tile = struct {
    wchar: c.wchar_t,
    is_walkable: bool,

    pub const wall = Self{ .wchar = '#', .is_walkable = false };
    pub const floor = Self{ .wchar = '.', .is_walkable = true };
    pub const out_of_map = Self{ .wchar = 'X', .is_walkable = false };

    const Self = @This();
};

pub const Entity = struct {
    pos: game.Position,
    wchars: [Self.diameter][Self.diameter]c.wchar_t,

    pub fn init(start_pos: game.Position, utf8_rows: [Self.diameter][]const u8) Self {
        var wchars: @FieldType(Self, "wchars") = undefined;
        for (0.., utf8_rows) |i, row| {
            var j: usize, var utf8 = .{ 0, (unicode.Utf8View.init(row) catch unreachable).iterator() };
            while (utf8.nextCodepoint()) |codepoint| {
                wchars[i][j] = @intCast(codepoint);
                j += 1;
            }
            assert(j == Self.diameter);
        }
        return .{ .pos = start_pos, .wchars = wchars };
    }

    pub fn maybeMoveBy(ent: *Self, dy: c_int, dx: c_int) void {
        const pos = game.Position{ .y = ent.pos.y + dy, .x = ent.pos.x + dx };
        {
            const radius = Self.diameter / 2;
            var y, var x = .{ pos.y - radius, pos.x - radius };
            for (ent.wchars) |row| {
                for (row) |wchar| {
                    defer x += 1;
                    if (' ' == wchar) continue;
                    if (!g.map.tile(y, x).is_walkable) return;
                }
                x -= Self.diameter;
                y += 1;
            }
        }
        ent.pos = pos;
    }

    pub fn draw(ent: *Self) void {
        const radius = Self.diameter / 2;
        var pos = game.Position{ .x = ent.pos.x - radius - g.cam.x, .y = ent.pos.y - radius - g.cam.y };
        for (ent.wchars) |row| {
            for (row) |wchar| {
                defer pos.x += 1;
                if (' ' == wchar or
                    0 > pos.x or pos.x >= g.stdscr.width or
                    0 > pos.y or pos.y >= g.stdscr.height) continue;

                // ok(c.mvaddch(pos.y, pos.x, @intCast(wchar))); // simpler than `mvadd_wch`, but ascii-only.

                var cchar: c.cchar_t = undefined;
                ok(c.setcchar(&cchar, &[_:0]@TypeOf(wchar){wchar}, 0, 0, null));
                ok(c.mvadd_wch(pos.y, pos.x, &cchar));
            }
            pos.x -= Self.diameter;
            pos.y += 1;
        }
    }

    const Self = @This();
    const diameter = 3;
};

pub fn init() void {}

pub fn deinit() void {
    g.mouse, g.cam, g.stdscr.width, g.stdscr.height = .{undefined} ** 4;
}

pub fn draw() void {
    ok(c.clear());
    g.stdscr.width, g.stdscr.height = .{ c.getmaxx(c.stdscr), c.getmaxy(c.stdscr) };
    g.cam.x, g.cam.y =
        .{ g.pl.pos.x - @divTrunc(g.stdscr.width, 2), g.pl.pos.y - @divTrunc(g.stdscr.height, 2) };
    g.map.draw();
    g.pl.draw();
}

pub fn loop() void {
    game.draw();

    while (true) {
        {
            const ch = c.getch();
            if (ch == 'q') break;
            game.handleInput(ch) orelse continue;
        }
        game.draw();
    }
}

pub fn handleInput(key: c_int) ?void {
    switch (key) {
        c.KEY_UP => g.pl.maybeMoveBy(-1, 0), // move up
        c.KEY_DOWN => g.pl.maybeMoveBy(1, 0), // move down
        c.KEY_LEFT => g.pl.maybeMoveBy(0, -1), // move left
        c.KEY_RIGHT => g.pl.maybeMoveBy(0, 1), // move right
        'p' => {
            _ = c.printw("\npl = %d, %d; cam = %d, %d", g.pl.pos.x, g.pl.pos.y, g.cam.x, g.cam.y);
            return null;
        },
        't' => {
            _ = c.printw("\ng.if_xterm.is = %d", g.if_xterm.is);
            return null;
        },
        'z' => {
            _ = c.printw("\n'z': mouse pos = %d, %d", g.mouse.x, g.mouse.y);
            return null;
        },
        c.KEY_MOUSE => {
            var event: c.MEVENT = undefined;
            ok(c.nc_getmouse(&event));
            g.mouse.x, g.mouse.y = .{ event.x, event.y };

            const report_mouse_pos: @TypeOf(event.bstate) = c.REPORT_MOUSE_POSITION;
            if (0 != (event.bstate & ~report_mouse_pos))
                _ = c.printw("\nc.KEY_MOUSE: mouse pos = %d, %d", g.mouse.x, g.mouse.y);

            return null;
        },
        else => {
            _ = c.printw("\nunhandled key = %d", key);
            return null;
        },
    }
}

const assert = debug.assert;
const c = @import("c.zig").c;
const debug = std.debug;
const g = @import("g.zig");
const game = @This();
const ok = @import("gcu.zig").ok;
const std = @import("std");
const unicode = std.unicode;
