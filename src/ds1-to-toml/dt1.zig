pub const tile = struct {
    pub const Hash = struct {
        table: dt1.tile.Hash.Table,

        pub const Table = std.AutoHashMap(dt1.tile.Id, dt1.tile.Self);

        pub fn loadAdd(ha: *Self, filepath_dt1: []const u8) !void {
            const file = try fs.cwd().openFile(filepath_dt1, .{});
            defer file.close();

            var br = io.bufferedReader(file.reader());
            var cr = io.countingReader(br.reader());
            const r = cr.reader();

            const he = try r.readStruct(dt1.FileHeader); // FIXME to `...readStructEndian(_ , .little);`
            assert(meta.eql(he.version, .{ 7, 6 }));
            assert(mem.allEqual(u8, he.zeroes_for_name[0..], 0));
            assert(cr.bytes_read == he.tile.first.file_offset);
            if (he.tile.count <= 0) return;

            var block: struct { first: struct { file_offset: i32 } } = undefined;
            var ti: dt1.tile.Self = undefined;
            for (0..@intCast(he.tile.count)) |i| {
                ti = try r.readStruct(@TypeOf(ti)); // FIXME to `...readStructEndian(_ , .little);`
                inline for (.{
                    "zero_height_to_bottom",
                    "zero_byte",
                    "zero_cache_idx",
                    "zero_u32",
                    "usually_zero_name_ptr",
                    "zero_lru_cache_block_ptr",
                }) |field_name| assert(mem.allEqual(u8, mem.asBytes(&@field(ti, field_name)), 0));
                assert(0 == ti.block.zero_ptr);
                if (0 == ti.width or 0 == ti.total_height)
                    assert(0 == ti.width and 0 == ti.total_height);
                {
                    const res = try ha.table.getOrPut(ti.id);
                    const res_ti = res.value_ptr;
                    if (!res.found_existing or
                        ti.rarity_or_frame_idx >= res_ti.rarity_or_frame_idx or
                        ti.width != 0 and res_ti.width == 0)
                    {
                        res_ti.* = ti;
                    }
                }
                if (0 == i) block.first.file_offset = ti.block.first.file_offset;
            }
            assert(cr.bytes_read == block.first.file_offset);
        }

        const Self = @This();
    };
    pub const Id = meta.Align(@alignOf(i32), extern struct {
        orientation_type: dt1.tile.OrientationType,
        style_idx: u8,
        sequence_subidx: u8,
    });
    pub const OrientationType = enum(u8) {
        floor = 0,
        _,
    };
    pub usingnamespace struct {
        pub const Self = meta.Align(1, extern struct {
            light_direction: i32,
            roof_height: u16,
            material_flags: packed struct(u16) {
                is_lava: bool,
                unknown_bit: u1,
                is_snow: bool,
                unknown_u5: u5,

                is_other: bool,
                is_water: bool,
                is_wood_object: bool,
                is_inside_stone: bool,
                is_outside_stone: bool,
                is_dirt: bool,
                is_sand: bool,
                is_wood: bool,
            },
            total_height: i32,
            width: i32,
            zero_height_to_bottom: i32,
            id: dt1.tile.Id,
            rarity_or_frame_idx: i32,
            transparent_color_rgb24: i32,
            subtile_flags: [
                dt1.tile.subtiles_per_dimension *
                    dt1.tile.subtiles_per_dimension
            ]packed struct(u8) {
                is_block_walk: bool,
                is_block_light_and_line_of_sight: bool,
                is_block_jump_and_teleport: bool,
                is_block_player_walk: bool,
                unknown_bit: u1,
                is_block_light_only: bool,
                unknown_u2: u2,
            },
            zero_byte: u8,
            zero_cache_idx: u16,
            zero_u32: u32,
            block: extern struct {
                first: extern struct { file_offset: i32 },
                size: i32,
                count: i32,
                zero_ptr: i32,
            },
            usually_zero_name_ptr: i32,
            zero_lru_cache_block_ptr: i32,
        });
    };
    pub const subtiles_per_dimension = 5;
};

const FileHeader = meta.Align(1, extern struct {
    version: [2]i32,
    zeroes_for_name: [260]u8,
    tile: extern struct {
        count: i32,
        first: extern struct { file_offset: i32 },
    },
});

const assert = debug.assert;
const debug = std.debug;
const dt1 = @import("dt1.zig");
const fs = std.fs;
const io = std.io;
const mem = std.mem;
const meta = @import("meta.zig");
const std = @import("std");
