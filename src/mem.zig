const std = @import("std");

fn list(allocator: std.mem.Allocator, outerList: *std.ArrayList(std.ArrayList(usize))) !void {
    var innerList1 = std.ArrayList(usize).init(allocator);
    try outerList.append(innerList1);
    try innerList1.append(@as(usize, 4));
    try innerList1.append(@as(usize, 5));

    std.debug.assert(innerList1.items.len == 2);
    std.debug.assert(innerList1.items[0] == 4);
    std.debug.assert(innerList1.items[1] == 5);

    var innerList2: std.ArrayList(usize) = outerList.items[0];
    try innerList2.append(@as(usize, 7));
    try innerList2.append(@as(usize, 8));
    try innerList2.append(@as(usize, 9));

    std.debug.assert(innerList2.items.len == 3);
    std.debug.assert(innerList2.items[0] == 7);
    std.debug.assert(innerList2.items[1] == 8);
    std.debug.assert(innerList2.items[1] == 9);

    std.debug.print("l1> {any}\n", .{innerList1.items});
    std.debug.print("l2> {any}\n", .{innerList2.items});
}

test "list" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var outerList = std.ArrayList(std.ArrayList(usize)).init(allocator);
    defer outerList.deinit();
    defer for (outerList.items) |item| item.deinit();

    try list(allocator, &outerList);
    try std.testing.expectEqual(@as(usize, 1), outerList.items.len);

    var innerList: std.ArrayList(usize) = outerList.items[0];
    try std.testing.expectEqual(std.ArrayList(usize), @TypeOf(innerList));
    try std.testing.expectEqual(@as(usize, 1), innerList.items.len);

    try std.testing.expectEqual(@as(usize, 4), innerList.items[0]);
    try std.testing.expectEqual(@as(usize, 5), innerList.items[1]);
}
