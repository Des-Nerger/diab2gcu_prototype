nodes: std.ArrayList(game.Position),
grid: Self.Grid,
queue: std.PriorityQueue(game.Position, Self.Grid, (struct {
    fn compare(gr: Self.Grid, a: game.Position, b: game.Position) math.Order {
        const cell: struct { a: *Self.Grid.Cell, b: *Self.Grid.Cell } = .{ .a = gr.cell(a), .b = gr.cell(b) };
        return switch (math.order(cell.a.heuristic, cell.b.heuristic)) {
            .eq => math.order(cell.b.dist, cell.a.dist), // Choosing the less speculative, more "accomplished".
            else => |order| order,
        };
    }
}).compare),

const Grid = struct {
    cells: []@This().Cell,
    width: c_int,

    const Cell = packed struct(u32) {
        dist: u14,
        heuristic: u15,
        prev_dir: game.Direction,

        var unvisited = @This(){ // Despite `var`, I hope no one will try to modify it ;)
            .dist = math.maxInt(@FieldType(@This(), "dist")),
            .heuristic = math.maxInt(@FieldType(@This(), "heuristic")),
            .prev_dir = undefined,
        };
    };

    fn cell(gr: @This(), pos: game.Position) *@This().Cell {
        var idx: usize = undefined;
        return &(if (0 > pos.x or pos.x >= gr.width or blk: {
            idx = @intCast(pos.y * gr.width + pos.x);
            break :blk 0 > idx or idx >= gr.cells.len;
        })
            @This().Cell.unvisited
        else
            gr.cells[idx]);
    }
};

pub fn deinit(pa: *Self) void {
    pa.nodes.deinit();
    pa.queue.deinit();
    g.allocator.free(pa.grid.cells);
    pa.* = undefined;
}

pub fn init(width: c_int, len: usize) Self {
    const grid =
        Grid{ .width = width, .cells = g.allocator.alloc(Self.Grid.Cell, len) catch unreachable };
    var queue = @FieldType(Self, "queue").init(g.allocator, grid);
    queue.ensureTotalCapacity(128 * 128) catch unreachable;
    return .{
        .nodes = @FieldType(Self, "nodes").initCapacity(g.allocator, 128) catch unreachable,
        .queue = queue,
        .grid = grid,
    };
}

pub fn maybeFindNewFor(pa: *Self, orig_ent: game.Entity, goal: game.Position) void {
    if (!g.map.tile(goal.y, goal.x).is_walkable) return;
    pa.queue.clearRetainingCapacity();
    @memset(pa.grid.cells, Self.Grid.Cell.unvisited);
    {
        const orig_cell = pa.grid.cell(orig_ent.pos);
        orig_cell.dist, orig_cell.heuristic = .{ 0, orig_ent.pos.octileDist(goal) };
    }
    pa.queue.add(orig_ent.pos) catch unreachable;
    while (0 < pa.queue.count()) {
        const visitor = pa.queue.remove();
        if (meta.eql(visitor, goal)) { // then reconstruct
            pa.nodes.clearRetainingCapacity();
            var node = goal;
            while (true) {
                const cell = pa.grid.cell(node);
                if (0 == cell.dist) break;
                pa.nodes.append(node) catch unreachable;
                node = .{ .x = node.x - cell.prev_dir.dx(), .y = node.y - cell.prev_dir.dy() };
            }
            return;
        }
        const visitor_dist = pa.grid.cell(visitor).dist;
        inline for (@typeInfo(game.Direction).@"enum".fields) |field| {
            const dir = @field(game.Direction, field.name);
            const dist = visitor_dist +| dir.stepLen();
            if (dist < math.maxInt(@TypeOf(dist))) {
                const pos = game.Position{ .x = visitor.x + dir.dx(), .y = visitor.y + dir.dy() };
                const neighbor = pa.grid.cell(pos);
                if (dist < neighbor.dist and !orig_ent.wouldCollideAt(pos)) {
                    const heuristic = dist +| pos.octileDist(goal);
                    if (heuristic < math.maxInt(@TypeOf(heuristic))) {
                        neighbor.* = .{ .prev_dir = dir, .dist = dist, .heuristic = heuristic };
                        // for (pa.queue.items) |queued_pos| // Cleaner, but worse performance-wise, I believe.
                        //     if (meta.eql(pos, queued_pos)) continue :outer;
                        pa.queue.add(pos) catch unreachable;
                    }
                }
            }
        }
    }
    // Couldn't find any path to the goal.
}

const Self = @This();
const g = @import("../g.zig");
const game = @import("../game.zig");
const math = std.math;
const meta = @import("../meta.zig");
const std = @import("std");
