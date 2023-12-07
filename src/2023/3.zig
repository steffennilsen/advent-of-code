const std = @import("std");
const data: []const u8 = @embedFile("./3");
const testData: []const u8 = @embedFile("./3.test");

pub fn main() !void {
    const stats = getDataStats(testData);
    const slice1 = testData[0..stats.width];
    const slice2 = testData[stats.width..(stats.width * 2)];

    std.debug.print("height: {d}\n", .{stats.height});
    std.debug.print("width (including \\n): {d}\n", .{stats.width});

    std.debug.print("###\n", .{});
    std.debug.print("{s}", .{slice1});
    std.debug.print("{s}", .{slice2});
    std.debug.print("###\n", .{});

    const it = SchematicIterator(u8, stats.height, stats.width);
    for (it.next()) |d| {
        std.debug.print("{any}", .{d});
    }
}

const DataStats = struct {
    height: usize,
    width: usize,
};

fn getDataStats(buffer: []const u8) DataStats {
    return DataStats{
        .lineCount = std.mem.count(u8, buffer, "\n") + 1,
        .lineWidth = std.mem.indexOf(u8, buffer, "\n").? + 1,
    };
}

// using std.mem.TokenIterator as example
fn SchematicIterator(comptime T: type, height: usize, width: usize) type {
    return comptime struct {
        buffer: []const T,
        index: usize = 0,
        height: height,
        width: width,

        const Self = @This();

        const Direction = enum {
            ne,
            n,
            nw,
            e,
            w,
            se,
            s,
            sw,

            pub fn isSouth(self: Direction) bool {
                return self == Direction.se or
                    self == Direction.s or
                    self == Direction.sw;
            }

            pub fn isNorth(self: Direction) bool {
                return self == Direction.ne or
                    self == Direction.n or
                    self == Direction.nw;
            }

            pub fn isEast(self: Direction) bool {
                return self == Direction.ne or
                    self == Direction.e or
                    self == Direction.se;
            }

            pub fn isWest(self: Direction) bool {
                return self == Direction.nw or
                    self == Direction.w or
                    self == Direction.sw;
            }
        };

        const SchematicNumber = struct {
            start: usize = 0,
            end: usize = 0,
            value: usize = 0,
            line: usize = 0,
            validIndex: ?usize,
        };

        pub fn next(self: *Self) ?SchematicNumber {
            const result = self.peek() orelse return null;
            self.index = result.end;
            self.line = result.line;
            return result;
        }

        pub fn peek(self: *Self) ?SchematicNumber {
            var cursor = self.index % self.width;
            _ = cursor;
            var sn: ?SchematicNumber = null;

            for ((self.index)..(self.buffer.len)) |i| {
                const c = self.buffer[i];
                switch (c) {
                    '0'...'9' => {
                        if (sn == null) {
                            const line = std.math.ceil(i / self.width);
                            sn = SchematicNumber{ .start = i, .line = line };

                            // east
                            const vi = self.getValidIndices(i, Direction{ Direction.ne, Direction.e, Direction.se });
                            if (vi != null) {
                                sn.?.validIndex = vi;
                            }
                        }

                        if (sn.?.validIndex == null) {
                            // north, south
                            const vi = self.getValidIndices(i, Direction{ Direction.n, Direction.s });
                            if (vi != null) {
                                sn.?.validIndex = vi;
                            }
                        }
                    },
                    else => {
                        if (sn != null) {
                            // we have a number
                            sn.?.end = i;
                            const nSlice = self.buffer[sn.?.start..sn.?.end];
                            sn.?.value = std.fmt.parseUnsigned(T, nSlice, 10);

                            if (sn.?.validIndex == null) {
                                // west
                                const vi = self.getValidIndices(i, Direction{ Direction.nw, Direction.w, Direction.sw });
                                if (vi != null) {
                                    sn.?.validIndex = vi;
                                }
                            }

                            return sn;
                        }
                    },
                }
            }

            return null;
        }

        pub fn rest(self: *Self) []const T {
            return self.buffer[(self.index)..(self.buffer.len)];
        }

        pub fn reset(self: *Self) void {
            self.index = 0;
        }

        /// returns first index that is valid
        pub fn getValidIndices(self: *Self, index: usize, directions: []self.Direction) ?usize {
            for (directions) |d| {
                const v = self.getValidDirectionIndex(index, d);

                if (v != null) {
                    return v;
                }
            }

            return null;
        }

        pub fn getValidDirectionIndex(self: *Self, index: usize, direction: self.Direction) ?usize {
            const line = std.math.ceil(index / self.width);
            if ((line == 0 and direction.isNorth()) or
                (line == self.height and direction.isSouth()))
            {
                return null;
            }

            if (line == self.height and direction.isSouth()) {
                return null;
            }

            const cursor = index % self.width;
            if (cursor == 0 and direction.isEast()) {
                return null;
            }

            if (cursor == self.width and direction.isWest()) {
                return null;
            }

            return switch (direction) {
                Direction.ne => index - self.width - 1,
                Direction.n => index - self.width,
                Direction.nw => index - self.width + 1,
                Direction.e => index - 1,
                Direction.w => index + 1,
                Direction.se => index + self.width - 1,
                Direction.s => index + self.width,
                Direction.sw => index + self.width + 1,
                else => unreachable,
            };
        }

        /// finds valid symbols
        pub fn isSymbol(self: *Self, index: usize, direction: self.Direction) ?usize {
            const validIndex = self.getValidDirectionIndex(index, direction);
            if (validIndex == null) {
                return null;
            }

            return switch (self.buffer[validIndex.?]) {
                '.' or '\n' or '0'...'9' => null,
                else => validIndex,
            };
        }
    };
}

test "getDataStats" {
    const actual = comptime getDataStats(testData);
    try std.testing.expectEqual(10, actual.height);
    try std.testing.expectEqual(11, actual.width);
}

// test "part1" {

// }
