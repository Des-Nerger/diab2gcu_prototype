init_seed_low: d2moo.Seed.Pair.Uint,
seed: d2moo.Seed,

pub fn init(level: *d2moo.Drlg.Level, drlg_type: d2moo.Drlg.Type) Self {
    _ = drlg_type;
    var room: Self = undefined;
    debug.print("{}.{s}:{}: ", .{ @This(), @src().fn_name, @src().line });
    room.seed = d2moo.Seed.initLow(@truncate(level.seed.rollRandomNumber()));
    debug.print("{}.{s}:{}: ", .{ @This(), @src().fn_name, @src().line });
    room.init_seed_low = @truncate(room.seed.rollRandomNumber());
    return room;
}

const Self = @This();
const d2moo = @import("../../d2moo.zig");
const debug = std.debug;
const std = @import("std");
