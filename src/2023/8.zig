const std = @import("std");

const Node = struct {
    L: ?*Node,
    R: ?*Node,
};

fn Map(comptime dir_len: usize, comptime nodes_len: usize) type {
    return struct {
        directions: [dir_len]u8,
        Nodes: [nodes_len]Node,
    };
}

pub fn main() !void {
    const data: []const u8 = @embedFile("./8");
    _ = data;
}

fn getOrPutNode(map: *std.StringHashMap(Node), key: []const u8) !Node {
    const v = try map.getOrPut(key);
    if (!v.found_existing) {
        v.value_ptr.* = Node{ .L = null, .R = null };
    }
    return v.value_ptr.*;
}

fn parseBuffer(allocator: std.mem.Allocator, buffer: []const u8) !void {
    var line_it = std.mem.tokenize(u8, buffer, "\n");
    const directions: []const u8 = line_it.next().?;
    _ = directions;

    var map = std.StringHashMap(Node).init(allocator);
    defer map.deinit();

    while (line_it.next()) |line| {
        const n_slice = line[0..3];
        const l_slice = line[7..10];
        const r_slice = line[12..15];

        const l = try getOrPutNode(&map, l_slice);
        const r = try getOrPutNode(&map, l_slice);
        const n = try getOrPutNode(&map, l_slice);

        const n_mr = try map.getOrPut(n_slice);
        if (!n_mr.found_existing) {
            n_mr.value_ptr.* = Node{ .L = undefined, .R = undefined };
        }
        const n = n_mr.value_ptr.*;
        _ = n;

        try map.put(n_slice, .{ l_slice, r_slice });
        std.debug.print("{s}, {s}, {s}\n", .{ n_slice, l_slice, r_slice });
    }

    const maps = [map.count()]Map;
    @memset(&maps, Node{});

    var node_key_it = map.valueIterator();
    while (node_key_it) |key| {
        _ = key;
    }
}

test "p1_1" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    const buffer: []const u8 = @embedFile("./8-1.test");
    try parseBuffer(allocator, buffer);
}
