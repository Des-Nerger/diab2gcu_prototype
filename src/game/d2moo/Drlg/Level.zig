drlg_type: d2moo.Drlg.Type,
id: d2moo.LevelId,
rooms_count: u32,
seed: d2moo.Seed,

pub fn init(drlg: *d2moo.Drlg, level_id: d2moo.LevelId) Self {
    debug.print(
        "{}.{s} | level_id:0x{X:08} + drlg.start_seed_low:0x{X:08}\n",
        .{ @This(), @src().fn_name, @intFromEnum(level_id), drlg.start_seed_low },
    );
    return .{
        .drlg_type = .maze, // FIXME get from "assets/excel/Levels.txt", instead
        .id = level_id,
        .rooms_count = 0,
        .seed = d2moo.Seed.initLow(@intFromEnum(level_id) + drlg.start_seed_low),
    };
}

pub fn generate(lev: *Self) void {
    switch (lev.drlg_type) {
        .maze => d2moo.Drlg.maze.generate(lev),
        .preset => {},
        .outdoor => {},
    }
}

const Self = @This();
const d2moo = @import("../../d2moo.zig");
const debug = std.debug;
const std = @import("std");
