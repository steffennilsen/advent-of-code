const std = @import("std");
const data = @embedFile("./5");
const test_data = @embedFile("./5.test");

pub fn main() !void {}

pub fn Almanac(comptime T: type) type {
    return struct {
        allocator: std.mem.Allocator,
        maps: AlmanacMap,
        seeds: std.ArrayList(usize),

        const Self = @This();

        pub const AlmanacKeys = enum {
            seeds_to_soil,
            soil_to_fertilizer,
            fertilizer_to_water,
            water_to_light,
            light_to_temperature,
            temperature_to_humidity,
            humidity_to_location,

            pub fn keyToEnum(key: []const T) ?AlmanacKeys {
                switch (key.len) {
                    12 => if (std.mem.eql(T, key, "seed-to-soil")) return AlmanacKeys.seeds_to_soil,
                    14 => if (std.mem.eql(T, key, "water-to-light")) return AlmanacKeys.water_to_light,
                    18 => if (std.mem.eql(T, key, "soil-to-fertilizer")) return AlmanacKeys.soil_to_fertilizer,
                    19 => if (std.mem.eql(T, key, "fertilizer-to-water")) return AlmanacKeys.fertilizer_to_water,
                    20 => {
                        if (std.mem.eql(T, key, "humidity-to-location")) return AlmanacKeys.humidity_to_location;
                        if (std.mem.eql(T, key, "light-to-temperature")) return AlmanacKeys.light_to_temperature;
                    },
                    23 => if (std.mem.eql(T, key, "temperature-to-humidity")) return AlmanacKeys.temperature_to_humidity,
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

        const AlmanacErrors = error{ ParseError, InternalError };
        const RangeList = std.ArrayList(Range);
        const AlmanacMap = std.AutoHashMap(AlmanacKeys, RangeList);

        pub fn init(allocator: std.mem.Allocator) !Self {
            var maps = AlmanacMap.init(allocator);
            var seeds = std.ArrayList(usize).init(allocator);

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
            while (maps_it.next()) |rl| {
                rl.deinit();
            }

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

        pub fn parseInput(self: *Self, buffer: []const T) !void {
            var it = std.mem.tokenizeAny(T, buffer, "\n");

            // seeds is a special case as the numbers are on the same line
            var seeds_line = it.next() orelse return AlmanacErrors.ParseError;
            var seeds_colon_index = std.mem.indexOf(T, seeds_line, ":") orelse return AlmanacErrors.ParseError;
            var seeds_slice = seeds_line[(seeds_colon_index + 1)..seeds_line.len];

            var seeds_it = std.mem.tokenizeAny(T, std.mem.trim(T, seeds_slice, " "), " ");
            while (seeds_it.next()) |s| {
                const t = std.mem.trim(T, s, " ");
                const n = try std.fmt.parseUnsigned(usize, t, 10);
                try self.seeds.append(n);
            }

            var key: AlmanacKeys = undefined;
            while (it.next()) |line| {
                if (line.len > 0 and !std.ascii.isDigit(line[0])) {
                    var colon_index = std.mem.indexOf(T, line, ":") orelse return AlmanacErrors.ParseError;
                    const slice = line[0..colon_index];
                    var map_it = std.mem.split(T, slice, " ");
                    const key_slice = map_it.next() orelse return AlmanacErrors.ParseError;
                    key = AlmanacKeys.keyToEnum(key_slice) orelse return AlmanacErrors.ParseError;
                } else {
                    var rl_ptr: *RangeList = self.maps.getPtr(key) orelse return AlmanacErrors.InternalError;
                    const range = try self.parseRange(line);
                    try rl_ptr.append(range);
                }
            }
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
    try almanac.parseInput(test_data);

    const seeds_li = almanac.seeds;
    try std.testing.expectEqual(@as(usize, 4), seeds_li.items.len);
    try std.testing.expectEqual(@as(usize, 79), seeds_li.items[0]);
    try std.testing.expectEqual(@as(usize, 14), seeds_li.items[1]);
    try std.testing.expectEqual(@as(usize, 55), seeds_li.items[2]);
    try std.testing.expectEqual(@as(usize, 13), seeds_li.items[3]);
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
    // defer almanac.denit();
    try almanac.parseInput(test_data);

    // checking first
    const sts_rl: RangeList = almanac.maps.get(MapKeys.seeds_to_soil).?;
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
    const htl_rl: RangeList = almanac.maps.get(MapKeys.humidity_to_location).?;
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
