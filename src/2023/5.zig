const std = @import("std");
const data = @embedFile("./5");
const test_data = @embedFile("./5.test");

pub fn main() !void {}

const AlmanacErrors = error{ ParseError, InternalError };

const Maps = enum {
    seeds,
    seeds_to_soil,
    soil_to_fertilizer,
    fertilizer_to_water,
    water_to_light,
    light_to_temperature,
    temperature_to_humidity,
    humidity_to_location,
};

pub fn Almanac(comptime T: type) type {
    return struct {
        allocator: std.mem.Allocator,
        map: std.AutoHashMap(Maps, std.ArrayList(usize)),

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator) !Self {
            var map = std.AutoHashMap(Maps, std.ArrayList(usize)).init(allocator);

            for (std.enums.values(Maps)) |m| {
                var list = std.ArrayList(usize).init(allocator);
                try map.put(m, list);
            }

            return Self{
                .allocator = allocator,
                .map = map,
            };
        }

        pub fn denit(self: *Self) void {
            var it = self.map.iterator();
            while (it.next()) |m| {
                m.value_ptr.*.deinit();
            }

            self.map.deinit();
        }

        fn parseNumbers(self: *Self, slice: []const T, list: *std.ArrayList(usize)) !void {
            _ = self;
            var it = std.mem.tokenize(T, std.mem.trim(T, slice, " "), " ");
            while (it.next()) |s| {
                const t = std.mem.trim(T, s, " ");
                if (t.len == 0) {
                    continue;
                }

                const n = try std.fmt.parseUnsigned(T, t, 10);
                try list.append(n);
            }
        }

        pub fn parseInput(self: *Self, buffer: []const T) !void {
            var it = std.mem.tokenize(T, buffer, "\n");

            // seeds is a special case as the numbers are on the same line
            var seeds_line = it.next() orelse return AlmanacErrors.ParseError;
            var seeds_colon_index = std.mem.indexOf(T, seeds_line, ":") orelse return AlmanacErrors.ParseError;
            var seeds_slice = seeds_line[(seeds_colon_index + 1)..seeds_line.len];
            var seeds_list: *std.ArrayList(usize) = self.map.getPtr(Maps.seeds).?;

            try self.parseNumbers(
                seeds_slice,
                seeds_list,
            );

            // while (it.next()) |l| {
            //     var line = std.mem.trim(T, l, " ");
            //     _ = line;
            // }
        }
    };
}

test "p1" {
    var arena: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var almanac = try Almanac(u8).init(allocator);
    defer almanac.denit();
    try almanac.parseInput(test_data);

    var seeds_list: *std.ArrayList(usize) = almanac.map.getPtr(Maps.seeds).?;

    try std.testing.expectEqual(@as(usize, 4), seeds_list.items.len);
    try std.testing.expectEqual(@as(usize, 79), seeds_list.items[0]);
    try std.testing.expectEqual(@as(usize, 14), seeds_list.items[1]);
    try std.testing.expectEqual(@as(usize, 55), seeds_list.items[2]);
    try std.testing.expectEqual(@as(usize, 13), seeds_list.items[3]);
}
