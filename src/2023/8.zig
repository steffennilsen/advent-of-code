const std = @import("std");

const Node = struct {
    id: [3]u8,
    l: *Node,
    r: *Node,
};

// fn Map(comptime dir_len: usize, comptime nodes_len: usize) type {
//     return struct {
//         directions: [dir_len]u8,
//         Nodes: [nodes_len]Node,
//     };
// }

const Map = struct {
    directions: []const u8,
    nodes: std.StringArrayHashMap(Node),

    fn deinit(self: Map) !void {
        self.nodes.deinit();
    }

    fn traverse(self: Map) usize {
        const zzz = self.nodes.getPtr("ZZZ") orelse unreachable;
        var node = self.nodes.getPtr("AAA") orelse unreachable;

        var steps: usize = 0;
        outer: while (true) {
            for (self.directions) |c| {
                if (node == zzz) {
                    break :outer;
                }

                switch (c) {
                    'L' => node = node.l,
                    'R' => node = node.r,
                    else => unreachable,
                }
                steps += 1;
            }
        }

        return steps;
    }
};

pub fn main() !void {
    const data: []const u8 = @embedFile("./8");
    _ = data;
}

fn parseBuffer(allocator: std.mem.Allocator, buffer: []const u8) !Map {
    var line_it = std.mem.tokenize(u8, buffer, "\n");
    const directions: []const u8 = line_it.next().?;

    var nodes = std.StringArrayHashMap(Node).init(allocator);
    const nodes_index = line_it.index;
    while (line_it.next()) |line| {
        var id = line[0..3];
        try nodes.put(id, Node{ .id = id.*, .l = undefined, .r = undefined });
    }

    line_it.index = nodes_index;
    while (line_it.next()) |line| {
        const node = nodes.getPtr(line[0..3]) orelse unreachable;
        const l = nodes.getPtr(line[7..10]) orelse unreachable;
        const r = nodes.getPtr(line[12..15]) orelse unreachable;
        node.*.l = l;
        node.*.r = r;
    }

    // var it = nodes.iterator();
    // while (it.next()) |e| {
    //     printNode(e.value_ptr.*);
    // }

    const map = Map{ .directions = directions, .nodes = nodes };
    return map;
}

fn printNode(node: Node) void {
    std.debug.print("[id: {s}, l: {s}, r: {s}]\n", .{
        node.id,
        node.l.*.id,
        node.r.*.id,
    });
}

test "p1_1" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    const buffer: []const u8 = @embedFile("./8-1.test");
    const map = try parseBuffer(allocator, buffer);

    try std.testing.expect(std.mem.eql(u8, "RL", map.directions));
    try std.testing.expectEqual(@as(usize, 7), map.nodes.count());

    const steps = map.traverse();
    try std.testing.expectEqual(@as(usize, 2), steps);
}

test "p1_2" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    const buffer: []const u8 = @embedFile("./8-2.test");
    const map = try parseBuffer(allocator, buffer);

    try std.testing.expect(std.mem.eql(u8, "LLR", map.directions));
    try std.testing.expectEqual(@as(usize, 3), map.nodes.count());

    const steps = map.traverse();
    try std.testing.expectEqual(@as(usize, 6), steps);
}
