//! Based on https://github.com/ThePhrozenKeep/D2MOO/tree/8322494ed1f715ad51552f169df76cf600fabc71/

pub const Act = enum {
    I,
    II,
    III,
    IV,
    V,
};

pub const Difficulty = enum {
    normal,
    nightmare,
    hell,
};

pub const Drlg = struct {
    act: d2moo.Act,
    difficulty: d2moo.Difficulty,
    seed: d2moo.Seed,
    start_seed_low: d2moo.Seed.Pair.Uint,
    level: Self.Level,

    pub const Level = @import("d2moo/Drlg/Level.zig");
    pub const Room = @import("d2moo/Drlg/Room.zig");
    pub const Type = enum(u2) { maze = 1, preset, outdoor };
    pub const maze = @import("d2moo/Drlg/maze.zig");

    pub fn init(
        act: d2moo.Act,
        difficulty: d2moo.Difficulty,
        player_given_seed_low: d2moo.Seed.Pair.Uint,
        level_id: d2moo.LevelId,
    ) Self {
        var d: Self = undefined;
        d.act = act;
        d.difficulty = difficulty;
        d.seed = Seed.initLow(player_given_seed_low);
        debug.print("{}.{s}:{}: ", .{ @This(), @src().fn_name, @src().line });
        d.start_seed_low = @truncate(d.seed.rollRandomNumber());
        d.level = Self.Level.init(&d, level_id);
        d.level.generate();
        return d;
    }

    const Self = @This();
};

pub const LevelId = enum(u8) {
    rogue_encampment = 1,
    blood_moor,
    cold_plains,
    den_of_evil = 8,
    cave_lev_1,
    cave_lev_2 = 13,
    burial_grounds = 17,
    crypt,
    mausoleum,
};

pub const Seed = packed union {
    uint: S.Uint,
    pair: S.Pair,

    pub fn initLow(low: @FieldType(S.Pair, "low")) S {
        debug.print("{}.{s}(0x{X:08})\n", .{ @This(), @src().fn_name, low });
        return .{ .pair = .{ .low = low, .high = 666 } };
    }

    pub fn rollRandomNumber(seed: *S) S.Uint {
        debug.print("0x{X:08}, 0x{X:08} --> ", .{ seed.pair.high, seed.pair.low });
        seed.uint = @as(S.Uint, 0x6AC690C5) * seed.pair.low + seed.pair.high;
        debug.print("0x{X:08}, 0x{X:08}\n", .{ seed.pair.high, seed.pair.low });
        return seed.uint;
    }

    pub fn rollLimitedRandomNumber(seed: *S, until: S.Pair.Uint) S.Pair.Uint {
        if (0 == until) return 0;
        _ = seed.rollRandomNumber();
        return seed.pair.low % until;
    }

    pub const Pair = packed struct {
        low: @This().Uint,
        high: @This().Uint,

        pub const Uint = blk: {
            const uint_info = @typeInfo(S.Uint).int;
            break :blk meta.Int(uint_info.signedness, uint_info.bits / 2);
        };
    };
    const S = @This();
    const Uint =
        if (.little == builtin.cpu.arch.endian()) u64 else @compileError("until zig#3380 is implemented");
};

const builtin = @import("builtin");
const d2moo = @This();
const debug = std.debug;
const meta = @import("meta.zig");
const std = @import("std");
