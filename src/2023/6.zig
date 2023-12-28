const std = @import("std");
const data = @embedFile("./6");
const data_size = 4;
const test_data = @embedFile("./6.test");
const test_data_size = 3;

const Race = struct {
    time: u32,
    distance: u32,
};

fn findRaceWinningCount(race: Race) usize {
    var count: usize = 0;

    for (0..race.time) |i| {
        const time_left = race.time - i;
        const distance = time_left * i;

        if (distance > race.distance) count += 1;
    }

    return count;
}

fn parseRaces(comptime T: type, buffer: []const T, comptime size: usize, races: *std.ArrayList(Race)) !void {
    var it_nl = std.mem.tokenize(T, buffer, "\n");
    const time_slice = it_nl.next() orelse unreachable;
    const distance_slice = it_nl.next() orelse unreachable;

    var time: [size]u32 = undefined;
    @memset(&time, 0);
    var time_it = std.mem.tokenize(T, time_slice, " ");
    _ = time_it.next(); // skip label
    for (0..size) |i| {
        const slice = time_it.next() orelse unreachable;
        const n: u32 = try std.fmt.parseUnsigned(T, slice, 10);
        time[i] = n;
    }

    var distance: [size]u32 = undefined;
    @memset(&distance, 0);
    var distance_it = std.mem.tokenize(T, distance_slice, " ");
    _ = distance_it.next(); // skip label
    for (0..size) |i| {
        const slice = distance_it.next() orelse unreachable;
        const n: u32 = try std.fmt.parseUnsigned(T, slice, 10);
        distance[i] = n;
    }

    for (0..size) |i| {
        const race = Race{
            .distance = distance[i],
            .time = time[i],
        };
        try races.append(race);
    }
}

test "p1_0" {
    var arena: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    var races = std.ArrayList(Race).init(allocator);
    defer races.deinit();
    try parseRaces(u8, test_data, test_data_size, &races);

    const expected: usize = 4;
    const actual = findRaceWinningCount(races.items[0]);
    try std.testing.expectEqual(expected, actual);
}

test "p1_1" {
    var arena: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    var races = std.ArrayList(Race).init(allocator);
    defer races.deinit();
    try parseRaces(u8, test_data, test_data_size, &races);

    const expected: usize = 8;
    const actual = findRaceWinningCount(races.items[1]);
    try std.testing.expectEqual(expected, actual);
}

test "p1_2" {
    var arena: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    var races = std.ArrayList(Race).init(allocator);
    defer races.deinit();
    try parseRaces(u8, test_data, test_data_size, &races);

    const expected: usize = 9;
    const actual = findRaceWinningCount(races.items[2]);
    try std.testing.expectEqual(expected, actual);
}
