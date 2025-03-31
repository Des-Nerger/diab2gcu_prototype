pub fn ok(result: c_int) void {
    if (c.OK != result)
        unreachable;
}

pub fn init() void {
    assert(null != c.setlocale(c.LC_CTYPE, ""));
    assert(c.initscr() == c.stdscr);

    ok(c.noecho());
    ok(c.keypad(c.stdscr, true));

    assert(0 != c.mousemask(c.ALL_MOUSE_EVENTS | c.REPORT_MOUSE_POSITION, null));
    g.if_xterm.detectIs();
    g.if_xterm.thenSetAnyEventMouse(true);
    assert(true == c.has_mouse());
    assert(1 == c.curs_set(0));
}

pub fn deinit() void {
    g.if_xterm.thenSetAnyEventMouse(false);
    g.if_xterm.is = undefined;
    ok(c.endwin());
}

const assert = debug.assert;
const c = @import("c.zig").c;
const debug = std.debug;
const g = @import("g.zig");
const std = @import("std");
