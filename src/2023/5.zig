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
                std.debug.print("init: {}\n", .{m});
                try map.put(m, std.ArrayList(usize).init(allocator));
            }

            return Self{
                .allocator = allocator,
                .map = map,
            };
        }

        pub fn denit(self: *Self) void {
            std.debug.print("deinit\n", .{});
            var it = self.map.iterator();
            while (it.next()) |m| {
                m.value_ptr.deinit();
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

                std.debug.print("[{s}]\n", .{s});
                const n = try std.fmt.parseUnsigned(T, t, 10);
                try list.*.append(n);
            }

            std.debug.print("pn> {any}\n", .{list.*.items});
        }

        pub fn parseInput(self: *Self, buffer: []const T) !void {
            var it = std.mem.tokenize(T, buffer, "\n");

            // seeds is a special case as the numbers are on the same line
            var seeds_line = it.next() orelse return AlmanacErrors.ParseError;
            var seeds_colon_index = std.mem.indexOf(T, seeds_line, ":") orelse return AlmanacErrors.ParseError;
            var seeds_slice = seeds_line[(seeds_colon_index + 1)..seeds_line.len];
            var seeds_list: std.ArrayList(usize) = self.map.get(Maps.seeds).?;
            try self.parseNumbers(
                seeds_slice,
                @constCast(seeds_list),
            );

            std.debug.print("pi> {}\n", .{Maps.seeds});
            std.debug.print("pi> {any}\n", .{seeds_list.*.items});
            std.debug.print("pi> {any}\n", .{self.map.get(Maps.seeds).?.items});

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

    const seeds_list: std.ArrayList(usize) = almanac.map.get(Maps.seeds).?;

    // std.debug.print("{any}\n", .{almanac.map});
    std.debug.print("p1> {any}\n", .{seeds_list.items});

    var it = almanac.map.iterator();
    while (it.next()) |list| {
        // std.debug.print("[{any}]\n", .{list});

        for (list.value_ptr.items) |v| {
            std.debug.print("[{d}]\n", .{v});
        }
    }

    try std.testing.expectEqual(@as(usize, 79), seeds_list.items[0]);
    try std.testing.expectEqual(@as(usize, 4), seeds_list.items.len);
}
