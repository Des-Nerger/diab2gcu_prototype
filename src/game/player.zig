pub fn init(start_pos: game.Position) game.Entity {
    return game.Entity.init(start_pos, .{
        " ╷ ",
        "╶@╴",
        " ╵ ",

        // " | ",
        // "-@-",
        // " | ",
    });
}

const game = @import("game.zig");
