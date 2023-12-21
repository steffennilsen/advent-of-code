const std = @import("std");

const T = usize;
const InnerList = std.ArrayList(usize);
const OuterList = std.ArrayList(*InnerList);

fn list(allocator: std.mem.Allocator, outerList: *OuterList) !void {
    std.debug.print("\n", .{});
    std.debug.print("ol: t > {}\n", .{@TypeOf(outerList)});
    std.debug.print("ol: t.*> {}\n", .{@TypeOf(outerList.*)});

    var innerList1 = InnerList.init(allocator);
    try outerList.append(innerList1);
    try innerList1.append(4);
    try innerList1.append(5);

    std.debug.assert(innerList1.items.len == 2);
    std.debug.assert(innerList1.items[0] == 4);
    std.debug.assert(innerList1.items[1] == 5);

    var innerList2: std.ArrayList(usize) = outerList.*.items[0];
    try innerList2.append(7);
    try innerList2.append(8);
    try innerList2.append(9);

    std.debug.assert(innerList2.items.len == 3);
    std.debug.assert(innerList2.items[0] == 7);
    std.debug.assert(innerList2.items[1] == 8);
    std.debug.assert(innerList2.items[2] == 9);

    std.debug.print("l1> {any}\n", .{innerList1.items});
    std.debug.print("l2> {any}\n", .{innerList2.items});

    std.debug.print("ol  > {any}\n", .{outerList.items.len});
    std.debug.print("ol.*> {any}\n", .{outerList.*.items.len});

    std.debug.print("ol  > {any}\n", .{outerList.items[0].items.len});
    std.debug.print("ol.*> {any}\n", .{outerList.*.items[0].items.len});
}

test "list" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var outerList = OuterList.init(allocator);
    defer outerList.deinit();
    defer for (outerList.items) |item| item.deinit();

    try list(allocator, &outerList);
    try std.testing.expectEqual(@as(usize, 1), outerList.items.len);

    var innerList: InnerList = outerList.items[0];
    try std.testing.expectEqual(InnerList, @TypeOf(innerList));
    try std.testing.expectEqual(@as(usize, 1), innerList.items.len);

    try std.testing.expectEqual(@as(usize, 4), innerList.items[0]);
    try std.testing.expectEqual(@as(usize, 5), innerList.items[1]);
}
