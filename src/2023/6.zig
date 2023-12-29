const std = @import("std");
const data = @embedFile("./6");
const data_size = 4;
const test_data = @embedFile("./6.test");
const test_data_size = 3;

const Race = struct {
    time: u32,
    distance: u32,
};

pub fn main() !void {
    var arena: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    const races = try parseRaces(u8, allocator, data, data_size, false);

    var p1: usize = 1;
    for (races.items) |race| {
        const rc = findRaceWinningCount(race);
        p1 *= rc;
    }

    std.debug.print("Part 1: {d}\n", .{p1});
}

fn findRaceWinningCount(race: Race) usize {
    var count: usize = 0;

    for (0..race.time) |i| {
        const time_left = race.time - i;
        const distance = time_left * i;

        if (distance > race.distance) count += 1;
    }

    return count;
}

/// https://ziglang.org/documentation/master/#toc-Memory
fn concat(comptime T: type, allocator: std.mem.Allocator, a: []T, b: []const T) ![]T {
    const result = try allocator.alloc(T, a.len + b.len);
    @memcpy(result[0..a.len], a);
    @memcpy(result[a.len..], b);
    return result;
}

fn parseRaces(
    comptime T: type,
    allocator: std.mem.Allocator,
    buffer: []const T,
    comptime size: usize,
    compound_races: bool,
) !std.ArrayList(Race) {
    var races = std.ArrayList(Race).init(allocator);

    var it_nl = std.mem.tokenize(T, buffer, "\n");
    const time_line = it_nl.next() orelse unreachable;
    const distance_line = it_nl.next() orelse unreachable;

    var time: [size]u32 = undefined;
    @memset(&time, 0);
    var time_slice: []T = &[_]T{};
    var time_it = std.mem.tokenize(T, time_line, " ");
    _ = time_it.next(); // skip label
    for (0..size) |i| {
        const slice: []const T = time_it.next() orelse unreachable;
        time_slice = try concat(T, allocator, time_slice, slice);
        const n: u32 = try std.fmt.parseUnsigned(u32, slice, 10);
        time[i] = n;
    }

    var distance: [size]u32 = undefined;
    @memset(&distance, 0);
    var distance_slice: []T = &[_]T{};
    var distance_it = std.mem.tokenize(T, distance_line, " ");
    _ = distance_it.next(); // skip label
    for (0..size) |i| {
        const slice = distance_it.next() orelse unreachable;
        distance_slice = try concat(T, allocator, distance_slice, slice);
        const n: u32 = try std.fmt.parseUnsigned(u32, slice, 10);
        distance[i] = n;
    }

    if (compound_races) {
        const compound_time = try std.fmt.parseUnsigned(u32, time_slice, 10);
        const compound_distance = try std.fmt.parseUnsigned(u32, distance_slice, 10);
        const race = Race{
            .distance = compound_distance,
            .time = compound_time,
        };
        try races.append(race);
    } else {
        for (0..size) |i| {
            const race = Race{
                .distance = distance[i],
                .time = time[i],
            };
            try races.append(race);
        }
    }

    return races;
}

test "p1" {
    var arena: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    const races = try parseRaces(u8, allocator, test_data, test_data_size, false);

    {
        const expected: usize = 4;
        const actual = findRaceWinningCount(races.items[0]);
        try std.testing.expectEqual(expected, actual);
    }

    {
        const expected: usize = 8;
        const actual = findRaceWinningCount(races.items[1]);
        try std.testing.expectEqual(expected, actual);
    }

    {
        const expected: usize = 9;
        const actual = findRaceWinningCount(races.items[2]);
        try std.testing.expectEqual(expected, actual);
    }
}

test "p2" {
    var arena: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    const races = try parseRaces(u8, allocator, test_data, test_data_size, true);
    {
        const expected: usize = 71503;
        const actual = findRaceWinningCount(races.items[0]);
        try std.testing.expectEqual(expected, actual);
    }
}
