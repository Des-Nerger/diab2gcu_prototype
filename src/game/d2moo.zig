/// Based on info from https://github.com/ThePhrozenKeep/D2MOO/blob/8322494/source/D2Common/include/D2Seed.h
pub const Seed = packed union {
    uint: S.Uint,
    pair: S.Pair,

    pub fn initLow(low: @FieldType(S.Pair, "low")) S {
        return .{ .pair = .{ .low = low, .high = 666 } };
    }

    pub fn rollRandomNumber(seed: *S) S.Uint {
        seed.uint = @as(S.Uint, 0x6AC690C5) * seed.pair.low + seed.pair.high;
        return seed.uint;
    }

    pub fn rollLimitedRandomNumber(seed: *S, until: S.Pair.Uint) S.Pair.Uint {
        if (0 == until) return 0;
        _ = seed.rollRandomNumber();
        return seed.pair.low % until;
    }

    const Pair = packed struct {
        low: @This().Uint,
        high: @This().Uint,

        const Uint = blk: {
            const uint_info = @typeInfo(S.Uint).int;
            break :blk meta.Int(uint_info.signedness, uint_info.bits / 2);
        };
    };
    const S = @This();
    const Uint =
        if (.little == builtin.cpu.arch.endian()) u64 else @compileError("until zig#3380 is implemented");
    const builtin = @import("builtin");
    const meta = std.meta;
    const std = @import("std");
};
