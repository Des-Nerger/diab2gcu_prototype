pub const c = @cImport({
    if (.windows == @import("builtin").os.tag) {
        @cDefine("PDC_WIDE", {});
        @cDefine("PDC_NCMOUSE", {});
    }
    @cDefine("nc_getmouse", "getmouse");
    @cInclude("curses.h");
    @cInclude("locale.h");
});
