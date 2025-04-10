pub const Direction = enum(u3) {
    // zig fmt: off
    north_west, // clock_10_30,
    north,      // clock_12_00,
    north_east, // clock_01_30,
    west,       // clock_09_00,
    east,       // clock_03_00,
    south_west, // clock_07_30,
    south,      // clock_06_00,
    south_east, // clock_04_30,
    // zig fmt: on

    pub fn dx(dir: Self) i2 {
        return ([_]i2{ -1, 0, 1, -1, 1, -1, 0, 1 })[@intFromEnum(dir)];
    }

    pub fn dy(dir: Self) i2 {
        return ([_]i2{ -1, -1, -1, 0, 0, 1, 1, 1 })[@intFromEnum(dir)];
    }

    pub fn stepLen(dir: Self) u8 {
        return if (0 == dir.dx() or 0 == dir.dy()) fp.one else fp.sqrt2;
    }

    const Self = @This();
};

pub const Position = struct {
    y: c_int,
    x: c_int,

    pub fn toWorldPos(scr: Self) Self {
        return .{ .x = scr.x + g.cam.x, .y = scr.y + g.cam.y };
    }

    pub fn toScreenPos(world: Self) Self {
        return .{ .x = world.x - g.cam.x, .y = world.y - g.cam.y };
    }

    pub fn octileDist(a: Self, b: Self) u14 {
        const dx_abs, const dy_abs = .{ @abs(a.x - b.x), @abs(a.y - b.y) };
        const min, const max = [_]u14{ @intCast(@min(dx_abs, dy_abs)), @intCast(@max(dx_abs, dy_abs)) };
        return fp.sqrt2 * min + fp.one * (max - min);
    }

    const Self = @This();
};

pub const Tile = struct {
    wchar: c.wchar_t,
    is_walkable: bool,

    pub const wall = Self{ .wchar = common.char.wall, .is_walkable = false };
    pub const floor = Self{ .wchar = common.char.floor, .is_walkable = true };
    pub const out_of_map = Self{ .wchar = common.char.out_of_map, .is_walkable = false };

    const Self = @This();
};

pub const Entity = struct {
    pos: game.Position,
    wchars: [Self.diameter][Self.diameter]c.wchar_t,

    pub const Path = @import("Entity/Path.zig");
    pub const radius = Self.diameter / 2;

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

    pub fn maybeStepAlong(ent: *Self, ent_path: *game.Entity.Path) void {
        if (ent_path.nodes.pop()) |node| ent.pos = node;
    }

    pub fn wouldCollideAt(ent: Self, pos: game.Position) bool {
        var y, var x = .{ pos.y - Self.radius, pos.x - Self.radius };
        for (ent.wchars) |row| {
            for (row) |wchar| {
                defer x += 1;
                if (' ' == wchar) continue;
                if (!g.map.tile(y, x).is_walkable) return true;
            }
            x -= Self.diameter;
            y += 1;
        }
        return false;
    }

    pub fn maybeMoveBy(ent: *Self, dy: c_int, dx: c_int) void {
        const pos = game.Position{ .y = ent.pos.y + dy, .x = ent.pos.x + dx };
        if (!ent.wouldCollideAt(pos))
            ent.pos = pos;
    }

    pub fn draw(ent: *Self) void {
        var scr =
            (game.Position{ .x = ent.pos.x - Self.radius, .y = ent.pos.y - Self.radius }).toScreenPos();
        for (ent.wchars) |row| {
            for (row) |wchar| {
                defer scr.x += 1;
                if (' ' == wchar or
                    0 > scr.x or scr.x >= c.COLS or
                    0 > scr.y or scr.y >= c.LINES) continue;

                // ok(c.mvaddch(scr.y, scr.x, @intCast(wchar))); // simpler than `mvadd_wch`, but ascii-only.

                var cchar: c.cchar_t = undefined;
                ok(c.setcchar(&cchar, &[_:0]@TypeOf(wchar){wchar}, 0, 0, null));
                ok(c.mvadd_wch(scr.y, scr.x, &cchar));
            }
            scr.x -= Self.diameter;
            scr.y += 1;
        }
    }

    const Self = @This();
    const diameter = 3;
};

/// -ixed_-oint_fractionals
pub const fp = struct {
    pub const one = 128; // == 1 * 2**7
    pub const sqrt2 = 181; // ≈ sqrt(2) * 2**7
};

pub fn init() void {
    g.ent_path = @TypeOf(g.ent_path).init(g.map.width, g.map.tiles.len);
}

pub fn deinit() void {
    g.ent_path.deinit();
    g.ent_path, g.mouse, g.cam = .{undefined} ** 3;
}

pub fn draw() void {
    g.pl.maybeStepAlong(&g.ent_path);
    ok(c.erase());
    g.cam.x, g.cam.y =
        .{ g.pl.pos.x - @divTrunc(c.COLS, 2), g.pl.pos.y - @divTrunc(c.LINES, 2) };
    g.map.draw();
    g.pl.draw();
    for (g.ent_path.nodes.items[0 .. @max(1, g.ent_path.nodes.items.len) - 1]) |world| {
        const scr = world.toScreenPos();
        if (0 <= scr.x and scr.x < c.COLS and 0 <= scr.y and scr.y < c.LINES) ok(c.mvaddch(scr.y, scr.x, '+'));
    }
    ok(c.refresh());
    ok(c.napms(175));
}

pub fn loop() void {
    game.draw();

    var maybe_ch: ?c_int = null;
    while (true) {
        switch (c.getch()) {
            c.ERR => {},
            'q' => break,
            c.KEY_MOUSE => |ch| {
                game.handleInput(ch) orelse continue;
                maybe_ch = null;
            },
            else => |ch| {
                maybe_ch = ch;
                continue;
            },
        }
        if (maybe_ch) |ch| {
            assert({} == game.handleInput(ch));
            maybe_ch = null;
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
        'z' => g.ent_path.maybeFindNewFor(g.pl, g.mouse.toWorldPos()),
        c.KEY_MOUSE => {
            var event: c.MEVENT = undefined;
            ok(c.nc_getmouse(&event));
            g.mouse.x, g.mouse.y = .{ event.x, event.y };

            if (0 != (event.bstate & ~@as(@TypeOf(event.bstate), c.REPORT_MOUSE_POSITION)))
                g.ent_path.maybeFindNewFor(g.pl, g.mouse.toWorldPos())
            else
                return null;
        },
        else => {},
    }
}

const assert = debug.assert;
const c = @import("c.zig").c;
const common = @import("common");
const debug = std.debug;
const g = @import("g.zig");
const game = @This();
const ok = @import("gcu.zig").ok;
const std = @import("std");
const unicode = std.unicode;
