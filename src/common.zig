pub fn LevelPreset(Ext: type) type {
    return struct {
        name: []u8,
        columns: usize,
        desc: [][]u8,

        pub const deinit = Ext.deinit;
        pub const init = Ext.init;
    };
}

pub const char = struct {
    pub const floor = '.';
    pub const out_of_map = @This().floor; // 'X';
    pub const unexpected = @This().floor; // '%';
    pub const wall = '#';
};
