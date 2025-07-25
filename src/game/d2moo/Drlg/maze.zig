pub fn generate(lev: *d2moo.Drlg.Level) void {
    _ = d2moo.Drlg.Room.init(lev, .preset);
    lev.rooms_count += 1; // TODO addRoom
    const rooms_count = 12; // FIXME get from "assets/excel/LvlMaze.txt"
    for (0..rooms_count) |_| {
        var rand_room = @This().getRandomRoom(lev);
        debug.print("{}.{s}:{}: ", .{ @This(), @src().fn_name, @src().line });
        _ = rand_room.seed.rollRandomNumber();
        break;
        // addAdjacentRoom
    }
}

// fprintf(stderr, "nRooms = %d\n", nRooms);
// while (pLevel->nRooms < nRooms)
// {
//     pRandomRoomEx = DRLGMAZE_GetRandomRoomExFromLevel(pLevel);
//     fprintf(stderr, "%s:%d: ", __func__, __LINE__);
//     nDirection = SEED_RollRandomNumber(&pRandomRoomEx->pSeed) & 3;
//     if (!DRLGMAZE_HasMapDS1(pRandomRoomEx))
//     {
//         DRLGMAZE_AddAdjacentMazeRoom(pRandomRoomEx, nDirection, 1);
//     }
// }
//
// fprintf(stderr, "%s:%d: ", __func__, __LINE__);
// nRand = SEED_RollRandomNumber(&pLevel->pSeed) & 3;

pub fn getRandomRoom(lev: *d2moo.Drlg.Level) *d2moo.Drlg.Room {
    _ = lev.seed.rollLimitedRandomNumber(lev.rooms_count);
    return undefined;
}

// fprintf(stderr, "%s:%d: ", __func__, __LINE__);
// for (int i = SEED_RollLimitedRandomNumber(&pLevel->pSeed, pLevel->nRooms); i; --i)

const d2moo = @import("../../d2moo.zig");
const debug = std.debug;
const std = @import("std");
