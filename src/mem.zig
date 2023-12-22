const std = @import("std");

const InnerList = std.ArrayList(usize);
const OuterList = std.ArrayList(*InnerList);
const Map = std.AutoHashMap(usize, *OuterList);

fn listOfLists(allocator: std.mem.Allocator, ol: *OuterList) !void {
    var il = InnerList.init(allocator);
    try ol.append(&il);
    try il.append(11);
    try il.append(12);
}

test "list of lists" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var ol = OuterList.init(allocator);
    try listOfLists(allocator, &ol);
    try std.testing.expectEqual(@as(usize, 1), ol.items.len);

    const il: *InnerList = ol.items[0];
    try std.testing.expectEqual(@as(usize, 2), il.items.len);
    try std.testing.expectEqual(@as(usize, 11), il.items[0]);
    try std.testing.expectEqual(@as(usize, 12), il.items[1]);
}

fn mapOfListsOfLists(allocator: std.mem.Allocator, map: *Map, key: usize) !void {
    var ol = OuterList.init(allocator);
    try map.put(key, &ol);
    try listOfLists(allocator, &ol);
}

test "map of list of lists" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const key: usize = 99;
    var map = Map.init(allocator);
    try mapOfListsOfLists(allocator, &map, key);
    try std.testing.expectEqual(@as(usize, 1), map.count());

    const ol: *OuterList = map.get(key).?;
    try std.testing.expectEqual(@as(usize, 1), ol.items.len);

    const il: *InnerList = ol.items[0];
    try std.testing.expectEqual(@as(usize, 2), il.items.len);
    try std.testing.expectEqual(@as(usize, 11), il.items[0]);
    try std.testing.expectEqual(@as(usize, 12), il.items[1]);
}

const List2 = std.ArrayList(usize);
const Map2 = std.AutoHashMap(usize, List2);

fn externalMapPut(allocator: std.mem.Allocator, map: *Map2) !void {
    var list = List2.init(allocator);
    try list.append(22);
    try map.put(11, list);
    // var list2: *List2 = map.getPtr(11).?;
    // try list2.append(33);
}

test "external map put" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var map = Map2.init(allocator);
    try externalMapPut(allocator, &map);
    try std.testing.expectEqual(@as(usize, 1), map.count());

    const list: List2 = map.get(11).?;
    try std.testing.expectEqual(List2, @TypeOf(list));
    try std.testing.expectEqual(@as(usize, 1), list.items.len);
    try std.testing.expectEqual(@as(usize, 22), list.items[0]);
    // try std.testing.expectEqual(@as(usize, 33), list.items[0]);
}
