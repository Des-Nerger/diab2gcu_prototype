pub const c = @cImport({
    if (.windows == @import("builtin").os.tag) {
        @cDefine("KEY_UP", "KEY_A2"); // wtf must these come before @cInclude and not after?! Idk.
        @cDefine("KEY_DOWN", "KEY_C2");
        @cDefine("KEY_LEFT", "KEY_B1");
        @cDefine("KEY_RIGHT", "KEY_B3");

        @cDefine("PDC_WIDE", {});
        @cDefine("PDC_NCMOUSE", {});
    } else @cDefine("nc_getmouse", "getmouse");
    @cInclude("curses.h");
    @cInclude("locale.h");
});
