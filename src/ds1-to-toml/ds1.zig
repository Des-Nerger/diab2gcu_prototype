pub const LevelPreset = common.LevelPreset(@This());

pub fn deinit(lp: *@This().LevelPreset, allocator: mem.Allocator) void {
    const alloc_bytes_ptr: [*]align(@alignOf([]u8)) u8 = @ptrCast(lp.desc.ptr);
    allocator.free(alloc_bytes_ptr[0 .. lp.desc.len * (@sizeOf([]u8) + lp.columns) + lp.name.len]);
    lp.* = undefined;
}

pub fn init(
    allocator: mem.Allocator,
    tile_table: dt1.tile.Hash.Table,
    filepath_ds1: []const u8,
) !@This().LevelPreset {
    const file = try fs.cwd().openFile(filepath_ds1, .{});
    defer file.close();

    var br = io.bufferedReader(file.deprecatedReader());
    const r = br.reader();

    const version = try r.readInt(i32, .little);
    assert(7 <= version and version <= 18);
    var cells_layer = struct { columns: usize, rows: usize, buf: std.BoundedArray(ds1.Cell, 8 * 1024) }{
        .columns = @intCast(1 + try r.readInt(i32, .little)),
        .rows = @intCast(1 + try r.readInt(i32, .little)),
        .buf = undefined,
    };
    cells_layer.buf = try @TypeOf(cells_layer.buf).init(cells_layer.columns * cells_layer.rows);
    var lp: @This().LevelPreset = undefined;
    lp.columns = @intCast(cells_layer.columns * dt1.tile.subtiles_per_dimension);
    lp.name, lp.desc = blk: {
        const file_stem = fs.path.stem(filepath_ds1);
        const rows = cells_layer.rows * dt1.tile.subtiles_per_dimension;
        const len = .{ .desc = rows * @sizeOf([]u8), .chars = rows * lp.columns + file_stem.len };
        const alloc_bytes = try allocator.alignedAlloc(
            u8,
            .fromByteUnits(@alignOf([]u8)),
            len.desc + len.chars,
        );
        const desc = mem.bytesAsSlice([]u8, alloc_bytes[0..len.desc]);
        var unused_chars = alloc_bytes[len.desc..];
        @memset(unused_chars[0 .. unused_chars.len - file_stem.len], common.char.out_of_map);
        for (desc) |*row|
            row.*, unused_chars = .{ unused_chars[0..lp.columns], unused_chars[lp.columns..] };
        @memcpy(unused_chars, file_stem);
        break :blk .{ unused_chars, desc };
    };
    assert(0 == if (8 > version) 0 else try r.readInt(i32, .little)); // act_idx
    _ = if (10 > version) 0 else try r.readInt(i32, .little); // tag_type
    for (0..@intCast(try r.readInt(i32, .little))) |_| try r.skipUntilDelimiterOrEof('\x00');
    if (9 <= version and version <= 13) try r.skipBytes(2 * @sizeOf(i32), .{});
    const wall_layers_count: usize = @intCast(try r.readInt(i32, .little));
    const floors_count: usize = @intCast(if (version < 16) 1 else try r.readInt(i32, .little));
    for (0..@intCast(2 * wall_layers_count + floors_count)) |i| {
        var cell_yx: usize, var char_y0: usize = .{ 0, dt1.tile.subtiles_per_dimension - 1 };
        for (0..cells_layer.rows) |_| {
            var char_x0: usize = 0;
            for (0..cells_layer.columns) |_| {
                defer {
                    cell_yx += 1;
                    char_x0 += dt1.tile.subtiles_per_dimension;
                }
                var cell = try r.readStruct(ds1.Cell);
                cell.prop1.orientation_type = blk: {
                    if (i < 2 * wall_layers_count) { // is_wall_layer
                        if (0 == i % 2) {
                            cells_layer.buf.set(cell_yx, cell);
                            continue;
                        } else { // is_orientation_type_layer
                            const orientation_type = cell.prop1.orientation_type;
                            cell = cells_layer.buf.get(cell_yx);
                            if (0 == cell.prop1.layer_drawing_priority) continue;
                            break :blk orientation_type;
                        }
                    } else {
                        if (0 == cell.prop1.layer_drawing_priority) continue;
                        break :blk .floor;
                    }
                };
                const tile_id = dt1.tile.Id{
                    .orientation_type = cell.prop1.orientation_type,
                    .style_idx = cell.style_idx,
                    .sequence_subidx = cell.sequence_subidx,
                };
                const maybe_subtile_flags = if (tile_table.getPtr(tile_id)) |tile|
                    tile.subtile_flags
                else blk: {
                    debug.print("\"{s}\" had out-of-table {}\n", .{ lp.name, tile_id });
                    break :blk null;
                };
                var sub_yx: usize, var char_y: usize = .{ 0, char_y0 };
                for (0..dt1.tile.subtiles_per_dimension) |_| {
                    var char_x = char_x0;
                    for (0..dt1.tile.subtiles_per_dimension) |_| {
                        defer {
                            sub_yx += 1;
                            char_x += 1;
                        }
                        lp.desc[char_y][char_x] = if (maybe_subtile_flags) |subtile_flags| blk: {
                            const subtile = subtile_flags[sub_yx];
                            if (subtile.is_block_walk or subtile.is_block_player_walk)
                                break :blk common.char.wall
                            else switch (lp.desc[char_y][char_x]) {
                                common.char.wall, common.char.unexpected => continue,
                                else => break :blk common.char.floor,
                            }
                        } else common.char.unexpected;
                    }
                    char_y -%= 1;
                }
            }
            char_y0 += dt1.tile.subtiles_per_dimension;
        }
    }
    return lp;
}

const Cell = packed struct(u32) {
    prop1: packed union {
        orientation_type: dt1.tile.OrientationType,
        layer_drawing_priority: u8,
    },
    sequence_subidx: u8,
    unknown_lower_u4: u4,
    style_idx: u6, // alternatively: u8
    unknown_higher_u4: u6, // alternatively: u4
};

const assert = debug.assert;
const common = @import("common");
const debug = std.debug;
const ds1 = @This();
const dt1 = @import("dt1.zig");
const fs = std.fs;
const io = std.io;
const mem = std.mem;
const std = @import("std");
