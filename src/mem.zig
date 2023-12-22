const std = @import("std");

const InnerList = std.ArrayList(usize);
const OuterList = std.ArrayList(InnerList);

fn external_fn(allocator: std.mem.Allocator, ol: *OuterList) !void {
    var li_1_1 = InnerList.init(allocator);
    try ol.append(li_1_1);
    try li_1_1.append(11);
}

test "list of lists" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var ol = OuterList.init(allocator);
    try external_fn(allocator, &ol);
    try std.testing.expectEqual(@as(usize, 1), ol.items.len);

    const il: InnerList = ol.items[0];
    try std.testing.expectEqual(@as(usize, 1), il.items.len);
    try std.testing.expectEqual(@as(usize, 11), il.items[0]);
}
