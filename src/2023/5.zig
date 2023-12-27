const std = @import("std");
const data = @embedFile("./5");
const test_data = @embedFile("./5.test");

pub fn main() !void {
    const T = u8;
    const TypedAlmanac = Almanac(T);
    const MapKeys = TypedAlmanac.AlmanacKeys;
    _ = MapKeys;

    var arena: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    var almanac_p1: TypedAlmanac = try Almanac(T).init(allocator);
    defer almanac_p1.denit();
    try almanac_p1.solve(data);

    var lowest_p1: usize = std.math.maxInt(usize);
    for (almanac_p1.seeds.items) |seed| {
        const location: usize = seed.location;
        if (location < lowest_p1) lowest_p1 = location;
    }

    var almanac_p2: TypedAlmanac = try Almanac(T).init(allocator);
    defer almanac_p2.denit();
    try almanac_p2.solve(data);
    const lowest_p2 = try almanac_p2.solveExpandSeedRanges();

    std.debug.print("part 1: {d}\n", .{lowest_p1});
    std.debug.print("part 2: {d}\n", .{lowest_p2});
}

pub fn Almanac(comptime T: type) type {
    return struct {
        allocator: std.mem.Allocator,
        maps: AlmanacMap,
        seeds: Seeds,

        const Self = @This();

        pub const AlmanacKeys = enum {
            soil,
            fertilizer,
            water,
            light,
            temperature,
            humidity,
            location,

            pub fn keyToEnum(key: []const T) ?AlmanacKeys {
                switch (key.len) {
                    12 => if (std.mem.eql(T, key, "seed-to-soil")) return AlmanacKeys.soil,
                    14 => if (std.mem.eql(T, key, "water-to-light")) return AlmanacKeys.light,
                    18 => if (std.mem.eql(T, key, "soil-to-fertilizer")) return AlmanacKeys.fertilizer,
                    19 => if (std.mem.eql(T, key, "fertilizer-to-water")) return AlmanacKeys.water,
                    20 => {
                        if (std.mem.eql(T, key, "humidity-to-location")) return AlmanacKeys.location;
                        if (std.mem.eql(T, key, "light-to-temperature")) return AlmanacKeys.temperature;
                    },
                    23 => if (std.mem.eql(T, key, "temperature-to-humidity")) return AlmanacKeys.humidity,
                    else => return null,
                }

                return null;
            }
        };

        const Range = struct {
            dst_start: usize,
            src_start: usize,
            len: usize,
        };

        const Seed = struct {
            id: usize,
            location: usize = 0,
        };

        const AlmanacErrors = error{ ParseError, InternalError };
        const RangeList = std.ArrayList(Range);
        const AlmanacMap = std.AutoHashMap(AlmanacKeys, RangeList);
        const Seeds = std.ArrayList(Seed);

        pub fn init(allocator: std.mem.Allocator) !Self {
            var maps = AlmanacMap.init(allocator);
            var seeds = Seeds.init(allocator);

            for (std.enums.values(AlmanacKeys)) |m| {
                var list = RangeList.init(allocator);
                try maps.put(m, list);
            }

            return Self{
                .allocator = allocator,
                .maps = maps,
                .seeds = seeds,
            };
        }

        pub fn denit(self: *Self) void {
            var maps_it = self.maps.valueIterator();
            while (maps_it.next()) |rl| rl.deinit();
            self.maps.deinit();
        }

        fn parseRange(self: Self, slice: []const T) !Range {
            _ = self;
            var it = std.mem.tokenizeAny(T, std.mem.trim(T, slice, " "), " ");
            var numbers: [3]usize = [_]usize{0} ** 3;

            var i: usize = 0;
            while (it.next()) |s| : (i += 1) {
                std.debug.assert(i < 3);
                const t = std.mem.trim(T, s, " ");
                const n = try std.fmt.parseUnsigned(usize, t, 10);
                numbers[i] = n;
            }

            const range = Range{
                .dst_start = numbers[0],
                .src_start = numbers[1],
                .len = numbers[2],
            };

            return range;
        }

        fn getKey(self: Self, line: []const T) !AlmanacKeys {
            _ = self;
            var colon_index = std.mem.indexOf(T, line, ":") orelse return AlmanacErrors.ParseError;
            const slice = line[0..colon_index];
            var it = std.mem.split(T, slice, " ");
            const key_slice = it.next() orelse return AlmanacErrors.ParseError;
            return AlmanacKeys.keyToEnum(key_slice) orelse return AlmanacErrors.ParseError;
        }

        fn parseSeeds(self: *Self, line: []const T) !void {
            var seeds_colon_index = std.mem.indexOf(T, line, ":") orelse return AlmanacErrors.ParseError;
            var slice = line[(seeds_colon_index + 1)..line.len];
            var it = std.mem.tokenizeAny(T, std.mem.trim(T, slice, " "), " ");

            // if (self.seed_range) {
            //     while (it.peek() != null) {
            //         const start_str = it.next() orelse return AlmanacErrors.ParseError;
            //         const start_trm = std.mem.trim(T, start_str, " ");
            //         const start = try std.fmt.parseUnsigned(usize, start_trm, 10);

            //         const len_str = it.next() orelse return AlmanacErrors.ParseError;
            //         const len_trm = std.mem.trim(T, len_str, " ");
            //         const len = try std.fmt.parseUnsigned(usize, len_trm, 10);

            //         for (start..(start + len)) |n| {
            //             const seed = Seed{ .id = n };
            //             try self.seeds.append(seed);
            //         }
            //     }
            // } else {
            while (it.next()) |s| {
                const t = std.mem.trim(T, s, " ");
                const n = try std.fmt.parseUnsigned(usize, t, 10);
                const seed = Seed{ .id = n };
                try self.seeds.append(seed);
            }
            // }
        }

        fn parseInput(self: *Self, buffer: []const T) !void {
            var it = std.mem.tokenizeAny(T, buffer, "\n");

            // seeds is a special case as the numbers are on the same line
            var seeds_line = it.next() orelse return AlmanacErrors.ParseError;
            try self.parseSeeds(seeds_line);

            var key: AlmanacKeys = undefined;
            while (it.next()) |line| {
                if (line.len > 0 and !std.ascii.isDigit(line[0])) {
                    key = try self.getKey(line);
                } else {
                    var rl_ptr: *RangeList = self.maps.getPtr(key) orelse return AlmanacErrors.InternalError;
                    const range = try self.parseRange(line);
                    try rl_ptr.append(range);
                }
            }
        }

        fn mapSeed(self: *Self, src: isize, key: AlmanacKeys) !usize {
            const ranges: RangeList = self.maps.get(key).?;
            const v: usize = for (ranges.items) |range| {
                const dst_start: isize = @intCast(range.dst_start);
                const src_start: isize = @intCast(range.src_start);
                const len: isize = @intCast(range.len);
                if ((src >= src_start) and (src < (src_start + len))) {
                    const diff: isize = dst_start - (src_start - src);
                    break @intCast(diff);
                }
            } else @intCast(src);

            return v;
        }

        fn mapSeeds(self: *Self) !void {
            for (self.seeds.items, 0..self.seeds.items.len) |seed, i| {
                const soil = try self.mapSeed(@intCast(seed.id), AlmanacKeys.soil);
                const fertilizer = try self.mapSeed(@intCast(soil), AlmanacKeys.fertilizer);
                const water = try self.mapSeed(@intCast(fertilizer), AlmanacKeys.water);
                const light = try self.mapSeed(@intCast(water), AlmanacKeys.light);
                const temperature = try self.mapSeed(@intCast(light), AlmanacKeys.temperature);
                const humidity = try self.mapSeed(@intCast(temperature), AlmanacKeys.humidity);
                const location = try self.mapSeed(@intCast(humidity), AlmanacKeys.location);
                self.seeds.items[i].location = location;
            }
        }

        pub fn solve(self: *Self, buffer: []const T) !void {
            try self.parseInput(buffer);
            try self.mapSeeds();
        }

        pub fn solveExpandSeedRanges(self: *Self) !usize {
            var lowest: usize = std.math.maxInt(usize);
            var i: usize = 0;
            while (i < self.seeds.items.len) : (i += 2) {
                const start = self.seeds.items[i].id;
                const len = self.seeds.items[i + 1].id;
                const end = start + len;

                for (start..end) |seed| {
                    const soil = try self.mapSeed(@intCast(seed), AlmanacKeys.soil);
                    const fertilizer = try self.mapSeed(@intCast(soil), AlmanacKeys.fertilizer);
                    const water = try self.mapSeed(@intCast(fertilizer), AlmanacKeys.water);
                    const light = try self.mapSeed(@intCast(water), AlmanacKeys.light);
                    const temperature = try self.mapSeed(@intCast(light), AlmanacKeys.temperature);
                    const humidity = try self.mapSeed(@intCast(temperature), AlmanacKeys.humidity);
                    const location = try self.mapSeed(@intCast(humidity), AlmanacKeys.location);

                    if (location < lowest) lowest = location;
                }
            }

            return lowest;
        }
    };
}

test "p1_seeds" {
    const T = u8;
    const TypedAlmanac = Almanac(T);

    var arena: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var almanac = try TypedAlmanac.init(allocator);
    defer almanac.denit();
    try almanac.solve(test_data);

    const seeds_li = almanac.seeds;
    try std.testing.expectEqual(@as(usize, 4), seeds_li.items.len);
    try std.testing.expectEqual(@as(usize, 79), seeds_li.items[0].id);
    try std.testing.expectEqual(@as(usize, 14), seeds_li.items[1].id);
    try std.testing.expectEqual(@as(usize, 55), seeds_li.items[2].id);
    try std.testing.expectEqual(@as(usize, 13), seeds_li.items[3].id);
}

test "p1_mappings" {
    const T = u8;
    const TypedAlmanac = Almanac(T);
    const MapKeys = TypedAlmanac.AlmanacKeys;
    const RangeList = TypedAlmanac.RangeList;

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var almanac: TypedAlmanac = try Almanac(T).init(allocator);
    defer almanac.denit();
    try almanac.solve(test_data);

    // checking first
    const sts_rl: RangeList = almanac.maps.get(MapKeys.soil).?;
    try std.testing.expectEqual(@as(usize, 2), sts_rl.items.len);

    const sts_range_1 = sts_rl.items[0];
    try std.testing.expectEqual(@as(usize, 50), sts_range_1.dst_start);
    try std.testing.expectEqual(@as(usize, 98), sts_range_1.src_start);
    try std.testing.expectEqual(@as(usize, 2), sts_range_1.len);

    const sts_range_2 = sts_rl.items[1];
    try std.testing.expectEqual(@as(usize, 52), sts_range_2.dst_start);
    try std.testing.expectEqual(@as(usize, 50), sts_range_2.src_start);
    try std.testing.expectEqual(@as(usize, 48), sts_range_2.len);

    // checking last
    const htl_rl: RangeList = almanac.maps.get(MapKeys.location).?;
    try std.testing.expectEqual(@as(usize, 2), htl_rl.items.len);

    const htl_range_1 = htl_rl.items[0];
    try std.testing.expectEqual(@as(usize, 60), htl_range_1.dst_start);
    try std.testing.expectEqual(@as(usize, 56), htl_range_1.src_start);
    try std.testing.expectEqual(@as(usize, 37), htl_range_1.len);

    const htl_range_2 = htl_rl.items[1];
    try std.testing.expectEqual(@as(usize, 56), htl_range_2.dst_start);
    try std.testing.expectEqual(@as(usize, 93), htl_range_2.src_start);
    try std.testing.expectEqual(@as(usize, 4), htl_range_2.len);
}

test "p1_seed_values" {
    const T = u8;
    const TypedAlmanac = Almanac(T);
    const Seed = TypedAlmanac.Seed;
    _ = Seed;
    const MapKeys = TypedAlmanac.AlmanacKeys;
    _ = MapKeys;
    const RangeList = TypedAlmanac.RangeList;
    _ = RangeList;

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var almanac: TypedAlmanac = try Almanac(T).init(allocator);
    defer almanac.denit();
    try almanac.solve(test_data);

    const seed_79 = for (almanac.seeds.items) |s| {
        if (s.id == 79) break s;
    } else unreachable;
    try std.testing.expectEqual(@as(usize, 79), seed_79.id);
    try std.testing.expectEqual(@as(usize, 82), seed_79.location);

    const seed_14 = for (almanac.seeds.items) |s| {
        if (s.id == 14) break s;
    } else unreachable;
    try std.testing.expectEqual(@as(usize, 14), seed_14.id);
    try std.testing.expectEqual(@as(usize, 43), seed_14.location);

    const seed_55 = for (almanac.seeds.items) |s| {
        if (s.id == 55) break s;
    } else unreachable;
    try std.testing.expectEqual(@as(usize, 55), seed_55.id);
    try std.testing.expectEqual(@as(usize, 86), seed_55.location);

    const seed_13 = for (almanac.seeds.items) |s| {
        if (s.id == 13) break s;
    } else unreachable;
    try std.testing.expectEqual(@as(usize, 13), seed_13.id);
    try std.testing.expectEqual(@as(usize, 35), seed_13.location);
}

test "p1_lowest" {
    const T = u8;
    const TypedAlmanac = Almanac(T);
    const MapKeys = TypedAlmanac.AlmanacKeys;
    _ = MapKeys;

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var almanac: TypedAlmanac = try Almanac(T).init(allocator);
    defer almanac.denit();
    try almanac.solve(test_data);

    var lowest: usize = std.math.maxInt(usize);
    for (almanac.seeds.items) |seed| {
        const location: usize = seed.location;
        if (location < lowest) lowest = location;
    }

    try std.testing.expectEqual(@as(usize, 35), lowest);
}

test "p2_lowest" {
    const T = u8;
    const TypedAlmanac = Almanac(T);
    const MapKeys = TypedAlmanac.AlmanacKeys;
    _ = MapKeys;

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var almanac: TypedAlmanac = try Almanac(T).init(allocator);
    defer almanac.denit();
    try almanac.solve(test_data);
    const lowest = try almanac.solveExpandSeedRanges();

    try std.testing.expectEqual(@as(usize, 46), lowest);
}
