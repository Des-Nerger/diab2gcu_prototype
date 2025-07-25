pub fn Align(alignment: comptime_int, Struct: type) type {
    var needs_reifying, var s = .{ false, @typeInfo(Struct).@"struct" };
    var fields: [s.fields.len]builtin.Type.StructField = undefined;
    @memcpy(fields[0..], s.fields);
    for (&fields) |*field| {
        if (alignment != field.alignment) {
            field.alignment = alignment;
            needs_reifying = true;
        }
        switch (@typeInfo(field.type)) {
            .@"struct" => |field_struct| {
                if (.@"packed" == field_struct.layout or
                    field.type == dt1.tile.Id) continue; // FIXME remove this second (kludge).
                const aligned_type = meta.Align(alignment, field.type);
                if (field.type != aligned_type) {
                    field.type = aligned_type;
                    needs_reifying = true;
                }
            },
            else => {},
        }
    }
    if (!needs_reifying) return Struct;
    s.fields = fields[0..];
    return @Type(.{ .@"struct" = s });
}
pub const eql = std.meta.eql;

const builtin = std.builtin;
const dt1 = @import("dt1.zig");
const meta = @This();
const std = @import("std");
