pub const Child = std.meta.Child;
pub const Int = std.meta.Int;
pub fn RemoveField(Struct: type, field_name: []const u8) type {
    var s = @typeInfo(Struct).@"struct";
    inline for (0.., s.fields) |i, field|
        if (mem.eql(u8, field_name, field.name)) {
            @memcpy(s.fields.ptr[i..], s.fields[i + 1 ..]);
            s.fields = s.fields[0 .. s.fields.len - 1];
            return @Type(.{ .@"struct" = s });
        };
}
pub const eql = std.meta.eql;

const mem = std.mem;
const std = @import("std");
