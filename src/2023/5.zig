const std = @import("std");
const data = @embedFile("./5");
const test_data = @embedFile("./5.test");

pub fn main() !void {}

pub fn Almanac(comptime T: type) type {
    return struct {
        allocator: std.mem.Allocator,
        buffer: []const T,
        line_it: std.mem.TokenIterator(T, .any),
        map: std.AutoHashMap(Maps, std.ArrayList(usize)),

        const Self = @This();

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

        pub fn init(allocator: std.mem.Allocator, buffer: []const T) !Self {
            var line_it = std.mem.tokenize(T, buffer, "\n");
            var map = std.AutoHashMap(Maps, std.ArrayList(usize)).init(allocator);

            for (std.enums.values(Maps)) |m| {
                try map.put(m, std.ArrayList(usize).init(allocator));
            }

            return Self{
                .allocator = allocator,
                .buffer = buffer,
                .line_it = line_it,
                .map = map,
            };
        }

        pub fn denit(self: *Self) void {
            var it = self.map.iterator();
            while (it.next()) |m| {
                m.value_ptr.deinit();
            }

            self.map.deinit();
        }
    };
}

test "p1" {
    var arena: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var almanac = try Almanac(u8).init(allocator, test_data);
    defer almanac.denit();
}
