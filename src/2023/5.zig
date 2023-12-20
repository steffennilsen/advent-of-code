const std = @import("std");
const data = @embedFile("./5");
const test_data = @embedFile("./5.test");

pub fn main() !void {}

const AlmanacErrors = error{ ParseError, InternalError };

pub fn Almanac(comptime T: type) type {
    return struct {
        allocator: std.mem.Allocator,
        maps: std.AutoHashMap(Maps, std.ArrayList(std.ArrayList(usize))),

        const Self = @This();

        pub const Maps = enum {
            seeds,
            seeds_to_soil,
            soil_to_fertilizer,
            fertilizer_to_water,
            water_to_light,
            light_to_temperature,
            temperature_to_humidity,
            humidity_to_location,

            pub fn keyToEnum(key: []const T) ?Maps {
                switch (key.len) {
                    5 => if (std.mem.eql(T, key, "seeds")) return Maps.seeds,
                    12 => if (std.mem.eql(T, key, "seed-to-soil")) return Maps.seeds_to_soil,
                    14 => if (std.mem.eql(T, key, "water-to-light")) return Maps.water_to_light,
                    18 => if (std.mem.eql(T, key, "soil-to-fertilizer")) return Maps.soil_to_fertilizer,
                    19 => if (std.mem.eql(T, key, "fertilizer-to-water")) return Maps.fertilizer_to_water,
                    20 => {
                        if (std.mem.eql(T, key, "humidity-to-location")) return Maps.humidity_to_location;
                        if (std.mem.eql(T, key, "light-to-temperature")) return Maps.light_to_temperature;
                    },
                    23 => if (std.mem.eql(T, key, "temperature-to-humidity")) return Maps.temperature_to_humidity,
                    else => return null,
                }

                return null;
            }
        };

        pub fn init(allocator: std.mem.Allocator) !Self {
            var maps = std.AutoHashMap(Maps, std.ArrayList(std.ArrayList(usize))).init(allocator);

            for (std.enums.values(Maps)) |m| {
                var list = std.ArrayList(std.ArrayList(usize)).init(allocator);
                try maps.put(m, list);
            }

            return Self{
                .allocator = allocator,
                .maps = maps,
            };
        }

        pub fn denit(self: *Self) void {
            var it = self.maps.iterator();
            while (it.next()) |m| {
                m.value_ptr.*.deinit();
            }

            self.maps.deinit();
        }

        fn parseNumbers(self: *Self, slice: []const T, list: *std.ArrayList(usize)) !void {
            _ = self;
            var it = std.mem.tokenizeAny(T, std.mem.trim(T, slice, " "), " ");

            while (it.next()) |s| {
                const t = std.mem.trim(T, s, " ");
                const n = try std.fmt.parseUnsigned(usize, t, 10);
                try list.*.append(n);
            }
        }

        pub fn parseInput(self: *Self, buffer: []const T) !void {
            var it = std.mem.tokenizeAny(T, buffer, "\n");
            var key: ?Maps = Maps.seeds;

            // seeds is a special case as the numbers are on the same line
            var seeds_line = it.next() orelse return AlmanacErrors.ParseError;
            var seeds_colon_index = std.mem.indexOf(T, seeds_line, ":") orelse return AlmanacErrors.ParseError;
            var seeds_slice = seeds_line[(seeds_colon_index + 1)..seeds_line.len];
            var seeds_ptr: *std.ArrayList(std.ArrayList(usize)) = self.maps.getPtr(Maps.seeds) orelse return AlmanacErrors.InternalError;
            var seeds_list = @constCast(&std.ArrayList(usize).init(self.allocator));
            try seeds_ptr.*.append(seeds_list.*);

            std.debug.print("!!<{s}>\n", .{seeds_line});

            try self.parseNumbers(
                seeds_slice,
                seeds_list,
            );

            std.debug.print("##{any}\n", .{(&self.maps.getPtr(Maps.seeds).?.*.items[0]).*.items});
            std.debug.print("@@{any}\n", .{seeds_list.items});

            key = null;
            while (it.next()) |line| {
                // std.debug.print("{any}[{s}].len={d}\n", .{ key, line, line.len });

                if (line.len > 0 and !std.ascii.isDigit(line[0])) {
                    var colon_index = std.mem.indexOf(T, line, ":") orelse return AlmanacErrors.ParseError;
                    const slice = line[0..colon_index];
                    var map_it = std.mem.split(T, slice, " ");
                    const key_slice = map_it.next() orelse return AlmanacErrors.ParseError;
                    // std.debug.print("{any}<{s}>.len={d}; #SETKEY\n", .{ key, key_slice, key_slice.len });
                    key = Maps.keyToEnum(key_slice) orelse return AlmanacErrors.ParseError;
                } else {
                    var list_ptr: *std.ArrayList(std.ArrayList(usize)) = self.maps.getPtr(key.?) orelse return AlmanacErrors.InternalError;
                    var numbers_list = std.ArrayList(usize).init(self.allocator);
                    try list_ptr.*.append(numbers_list);

                    var n_it = std.mem.split(T, line, " ");
                    while (n_it.next()) |s| {
                        const n = try std.fmt.parseUnsigned(T, s, 10);
                        // std.debug.print("{s}, {c}, {d}\n", .{ s, s, n });
                        try numbers_list.append(n);
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
    var arena: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const Maps = Almanac(u8).Maps;
    var almanac = try Almanac(u8).init(allocator);
    defer almanac.denit();
    try almanac.parseInput(test_data);

    // checking first
    const seeds_to_soil_list: *std.ArrayList(std.ArrayList(usize)) = almanac.maps.getPtr(Maps.seeds_to_soil).?;
    const seeds_to_soil: *std.ArrayList(usize) = &seeds_to_soil_list.*.items[0];
    std.debug.print("p1_mappings>{any}\n", .{seeds_to_soil.*.items});
    try std.testing.expectEqual(@as(usize, 2), seeds_to_soil.*.items.len);

    const seeds_to_soil_slice_1 = &seeds_to_soil_list.*.items[0];
    try std.testing.expectEqual(@as(usize, 3), seeds_to_soil_slice_1.*.items.len);
    try std.testing.expectEqual(@as(usize, 50), seeds_to_soil_slice_1.*.items[0]);
    try std.testing.expectEqual(@as(usize, 98), seeds_to_soil_slice_1.*.items[1]);
    try std.testing.expectEqual(@as(usize, 2), seeds_to_soil_slice_1.*.items[2]);

    const seeds_to_soil_slice_2 = &seeds_to_soil_list.*.items[0];
    try std.testing.expectEqual(@as(usize, 3), seeds_to_soil_slice_2.*.items.len);
    try std.testing.expectEqual(@as(usize, 52), seeds_to_soil_slice_2.*.items[0]);
    try std.testing.expectEqual(@as(usize, 50), seeds_to_soil_slice_2.*.items[1]);
    try std.testing.expectEqual(@as(usize, 48), seeds_to_soil_slice_2.*.items[2]);

    // checking last
    const humidity_to_location_list: *std.ArrayList(std.ArrayList(usize)) = almanac.maps.getPtr(Maps.humidity_to_location).?;
    try std.testing.expectEqual(@as(usize, 2), humidity_to_location_list.*.items.len);

    const humidity_to_location_slice_1 = &humidity_to_location_list.*.items[0];
    try std.testing.expectEqual(@as(usize, 3), humidity_to_location_slice_1.*.items.len);
    try std.testing.expectEqual(@as(usize, 60), humidity_to_location_slice_1.*.items[0]);
    try std.testing.expectEqual(@as(usize, 56), humidity_to_location_slice_1.*.items[1]);
    try std.testing.expectEqual(@as(usize, 37), humidity_to_location_slice_1.*.items[2]);

    const humidity_to_location_slice_2 = &humidity_to_location_list.*.items[0];
    try std.testing.expectEqual(@as(usize, 3), humidity_to_location_slice_2.*.items.len);
    try std.testing.expectEqual(@as(usize, 56), humidity_to_location_slice_2.*.items[0]);
    try std.testing.expectEqual(@as(usize, 93), humidity_to_location_slice_2.*.items[1]);
    try std.testing.expectEqual(@as(usize, 4), humidity_to_location_slice_2.*.items[2]);
}
