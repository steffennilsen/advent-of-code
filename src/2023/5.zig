const std = @import("std");
const data = @embedFile("./5");
const test_data = @embedFile("./5.test");

pub fn main() !void {}

pub fn Almanac(comptime T: type) type {
    return struct {
        allocator: std.mem.Allocator,
        maps: AlmanacMap,

        const Self = @This();

        pub const AlmanacKeys = enum {
            seeds,
            seeds_to_soil,
            soil_to_fertilizer,
            fertilizer_to_water,
            water_to_light,
            light_to_temperature,
            temperature_to_humidity,
            humidity_to_location,

            pub fn keyToEnum(key: []const T) ?AlmanacKeys {
                switch (key.len) {
                    5 => if (std.mem.eql(T, key, "seeds")) return AlmanacKeys.seeds,
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

        const AlmanacErrors = error{ ParseError, InternalError };
        const ListInner = std.ArrayList(usize);
        const ListOuter = std.ArrayList(*ListInner);
        const AlmanacMap = std.AutoHashMap(AlmanacKeys, ListOuter);

        pub fn init(allocator: std.mem.Allocator) !Self {
            var maps = AlmanacMap.init(allocator);

            for (std.enums.values(AlmanacKeys)) |m| {
                var list = ListOuter.init(allocator);
                try maps.put(m, list);
            }

            return Self{
                .allocator = allocator,
                .maps = maps,
            };
        }

        pub fn denit(self: *Self) void {
            var maps_it = self.maps.valueIterator();
            _ = maps_it;
            // while (maps_it.next()) |lo_ptr| {
            //     for (lo_ptr.*.items) |li_ptr| li_ptr.*.deinit();
            //     lo_ptr.*.deinit();
            // }

            self.maps.deinit();
        }

        fn parseNumbers(self: *Self, slice: []const T, list: *ListInner) !void {
            _ = self;
            var it = std.mem.tokenizeAny(T, std.mem.trim(T, slice, " "), " ");

            while (it.next()) |s| {
                const t = std.mem.trim(T, s, " ");
                const n = try std.fmt.parseUnsigned(usize, t, 10);
                try list.append(n);
            }
        }

        pub fn parseInput(self: *Self, buffer: []const T) !void {
            var it = std.mem.tokenizeAny(T, buffer, "\n");
            var key: ?AlmanacKeys = AlmanacKeys.seeds;

            // seeds is a special case as the numbers are on the same line
            var seeds_line = it.next() orelse return AlmanacErrors.ParseError;
            var seeds_colon_index = std.mem.indexOf(T, seeds_line, ":") orelse return AlmanacErrors.ParseError;
            var seeds_slice = seeds_line[(seeds_colon_index + 1)..seeds_line.len];
            var seeds_lo: ListOuter = self.maps.get(AlmanacKeys.seeds) orelse return AlmanacErrors.InternalError;
            var seeds_li = ListInner.init(self.allocator);
            try seeds_lo.append(&seeds_li);

            std.debug.print("!!<{s}>\n", .{seeds_line});

            try self.parseNumbers(
                seeds_slice,
                &seeds_li,
            );

            std.debug.print("##{any}\n", .{self.maps.get(AlmanacKeys.seeds).?.items[0].*.items});
            std.debug.print("@@{any}\n", .{seeds_li.items});

            key = null;
            while (it.next()) |line| {
                // std.debug.print("{any}[{s}].len={d}\n", .{ key, line, line.len });

                if (line.len > 0 and !std.ascii.isDigit(line[0])) {
                    var colon_index = std.mem.indexOf(T, line, ":") orelse return AlmanacErrors.ParseError;
                    const slice = line[0..colon_index];
                    var map_it = std.mem.split(T, slice, " ");
                    const key_slice = map_it.next() orelse return AlmanacErrors.ParseError;
                    // std.debug.print("{any}<{s}>.len={d}; #SETKEY\n", .{ key, key_slice, key_slice.len });
                    key = AlmanacKeys.keyToEnum(key_slice) orelse return AlmanacErrors.ParseError;
                } else {
                    var lo_ptr: ListOuter = self.maps.get(key.?) orelse return AlmanacErrors.InternalError;
                    var li: ListInner = std.ArrayList(usize).init(self.allocator);
                    try lo_ptr.append(&li);

                    var n_it = std.mem.split(T, line, " ");
                    while (n_it.next()) |s| {
                        const n = try std.fmt.parseUnsigned(T, s, 10);
                        // std.debug.print("{s}, {c}, {d}\n", .{ s, s, n });
                        try li.append(n);
                    }

                    // std.debug.print("l1> {any}\n", .{list_ptr.items});
                    // std.debug.print("l2> {any}\n", .{self.maps.getPtr(key.?).?.items});
                }
            }

            // std.debug.print("##############\n", .{});
        }
    };
}

// test "p1_seeds" {
//     var arena: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
//     defer arena.deinit();
//     const allocator = arena.allocator();

//     var almanac = try Almanac(u8).init(allocator);
//     defer almanac.denit();
//     try almanac.parseInput(test_data);

//     var seeds = almanac.seeds;
//     try std.testing.expectEqual(@as(usize, 4), seeds.items.len);
//     try std.testing.expectEqual(@as(usize, 79), seeds.items[0]);
//     try std.testing.expectEqual(@as(usize, 14), seeds.items[1]);
//     try std.testing.expectEqual(@as(usize, 55), seeds.items[2]);
//     try std.testing.expectEqual(@as(usize, 13), seeds.items[3]);
// }

test "p1_mappings" {
    const T = u8;
    const TypedAlmanac = Almanac(T);
    const Maps = TypedAlmanac.AlmanacKeys;
    const ListInner = TypedAlmanac.ListInner;
    const ListOuter = TypedAlmanac.ListOuter;
    std.debug.print("\n", .{});

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var almanac: TypedAlmanac = try Almanac(T).init(allocator);
    // defer almanac.denit();
    try almanac.parseInput(test_data);

    // checking first
    const seeds_to_soil_lo_ptr: ListOuter = almanac.maps.get(Maps.seeds_to_soil).?;
    try std.testing.expectEqual(@as(usize, 1), seeds_to_soil_lo_ptr.items.len);
    std.debug.print("p1_mappings.seeds_to_soil_list>{any}\n", .{seeds_to_soil_lo_ptr.items});
    const seeds_to_soil_li_ptr: *ListInner = seeds_to_soil_lo_ptr.items[0];
    std.debug.print("p1_mappings>{any}\n", .{seeds_to_soil_li_ptr.items});
    try std.testing.expectEqual(@as(usize, 2), seeds_to_soil_li_ptr.items.len);

    const seeds_to_soil_slice_1 = seeds_to_soil_lo_ptr.items[0];
    try std.testing.expectEqual(@as(usize, 3), seeds_to_soil_slice_1.items.len);
    try std.testing.expectEqual(@as(usize, 50), seeds_to_soil_slice_1.items[0]);
    try std.testing.expectEqual(@as(usize, 98), seeds_to_soil_slice_1.items[1]);
    try std.testing.expectEqual(@as(usize, 2), seeds_to_soil_slice_1.items[2]);

    const seeds_to_soil_slice_2 = seeds_to_soil_lo_ptr.items[0];
    try std.testing.expectEqual(@as(usize, 3), seeds_to_soil_slice_2.items.len);
    try std.testing.expectEqual(@as(usize, 52), seeds_to_soil_slice_2.items[0]);
    try std.testing.expectEqual(@as(usize, 50), seeds_to_soil_slice_2.items[1]);
    try std.testing.expectEqual(@as(usize, 48), seeds_to_soil_slice_2.items[2]);

    // checking last
    const humidity_to_location_lo_ptr: ListOuter = almanac.maps.get(Maps.humidity_to_location).?;
    try std.testing.expectEqual(@as(usize, 2), humidity_to_location_lo_ptr.items.len);

    const humidity_to_location_slice_1 = humidity_to_location_lo_ptr.items[0];
    try std.testing.expectEqual(@as(usize, 3), humidity_to_location_slice_1.items.len);
    try std.testing.expectEqual(@as(usize, 60), humidity_to_location_slice_1.items[0]);
    try std.testing.expectEqual(@as(usize, 56), humidity_to_location_slice_1.items[1]);
    try std.testing.expectEqual(@as(usize, 37), humidity_to_location_slice_1.items[2]);

    const humidity_to_location_slice_2 = humidity_to_location_lo_ptr.items[0];
    try std.testing.expectEqual(@as(usize, 3), humidity_to_location_slice_2.items.len);
    try std.testing.expectEqual(@as(usize, 56), humidity_to_location_slice_2.items[0]);
    try std.testing.expectEqual(@as(usize, 93), humidity_to_location_slice_2.items[1]);
    try std.testing.expectEqual(@as(usize, 4), humidity_to_location_slice_2.items[2]);
}
