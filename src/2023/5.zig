const std = @import("std");
const data = @embedFile("./5");
const test_data = @embedFile("./5.test");

pub fn main() !void {}

pub fn Almanac(comptime T: type) type {
    return struct {
        allocator: std.mem.Allocator,
        map: std.AutoHashMap(Maps, std.ArrayList(usize)),

        const Self = @This();

        const AlmanacErrors = error{
            ParseError,
        };

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

        pub fn init(allocator: std.mem.Allocator) !Self {
            var map = std.AutoHashMap(Maps, std.ArrayList(usize)).init(allocator);

            for (std.enums.values(Maps)) |m| {
                try map.put(m, std.ArrayList(usize).init(allocator));
            }

            return Self{
                .allocator = allocator,
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

        fn parseNumbers(slice: []const T, list: std.ArrayList(usize)) !type {
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

        pub fn parseInput(buffer: []const T) !void {
            var it = std.mem.tokenize(T, buffer, "\n");

            // seeds is a special case as the numbers are on the same line
            var seeds_line = it.next() orelse return AlmanacErrors.ParseError;
            var seeds_colon_index = std.mem.indexOf(T, seeds_line, ":") orelse return AlmanacErrors.ParseError;
            var seeds_slice = seeds_line[seeds_colon_index..seeds_line.len];
            var seeds = parseNumbers(seeds_slice);
            _ = seeds;

            while (it.next()) |l| {
                var line = std.mem.trim(T, l, " ");
                _ = line;
            }
        }
    };
}

test "p1" {
    var arena: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var almanac = try Almanac(u8).init(allocator);
    defer almanac.denit();

    const Maps = Almanac(u8).Maps;
    const seeds_list: std.ArrayList(usize) = almanac.map.get(Maps.seeds).?;
    const len: usize = @as(usize, seeds_list.items.len);

    try std.testing.expectEqual(4, len);
}
