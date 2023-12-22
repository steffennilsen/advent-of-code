const std = @import("std");

const InnerList = std.ArrayList(usize);
const OuterList = std.ArrayList(InnerList);
const Map = std.AutoHashMap(usize, OuterList);

fn external_fn(allocator: std.mem.Allocator, ol: OuterList) !void {
    var li_1_1 = InnerList.init(allocator);
    try ol.append(li_1_1);
    try li_1_1.append(11);
}

test "map" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var map = Map.init(allocator);
    defer map.deinit();

    var ol_1 = OuterList.init(allocator);
    try map.put(1, ol_1);
    try std.testing.expectEqual(@as(usize, 1), map.count());

    try external_fn(allocator, &ol_1);

    const li_1_1: InnerList = ol_1.items[0];
    try std.testing.expectEqual(@as(usize, 1), li_1_1.items.len);
    try std.testing.expectEqual(@as(usize, 11), li_1_1.items[0]);
}
