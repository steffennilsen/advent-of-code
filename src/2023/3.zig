const std = @import("std");
const data: []const u8 = @embedFile("./3");
const testData: []const u8 = @embedFile("./3.test");

pub fn main() !void {
    const stats = getDataStats(testData);
    const slice1 = testData[0..stats.width];
    _ = slice1;
    const slice2 = testData[stats.width..(stats.width * 2)];
    _ = slice2;

    // std.debug.print("height: {d}\n", .{stats.height});
    // std.debug.print("width (including \\n): {d}\n", .{stats.width});

    // std.debug.print("###\n", .{});
    // std.debug.print("{s}", .{slice1});
    // std.debug.print("{s}", .{slice2});
    // std.debug.print("###\n", .{});

    var it = SchematicIterator(u8){
        .buffer = testData,
        .height = stats.height,
        .width = stats.width,
    };
    // std.debug.print("it: {any}\n", .{it});
    // std.debug.print("peek: {any}\n", .{it.peek()});
    // std.debug.print("###\n", .{});
    // std.debug.print("it: {any}\n", .{it});

    while (it.next()) |n| {
        std.debug.print("{}\n", .{n});
        // std.debug.print("peek: {any}\n", .{it.peek()});
        // std.debug.print("\n", .{});
        // std.debug.print("###\n", .{});
    }

    // std.debug.print("peek: {any}\n", .{it.peek()});

    // for (it.next()) |d| {
    //     std.debug.print("{any}", .{d});
    // }
}

const DataStats = struct {
    height: usize,
    width: usize,
};

fn getDataStats(buffer: []const u8) DataStats {
    return DataStats{
        .height = std.mem.count(u8, buffer, "\n") + 1,
        .width = std.mem.indexOf(u8, buffer, "\n").? + 1,
    };
}

// using std.mem.TokenIterator as example
pub fn SchematicIterator(comptime T: type) type {
    return struct {
        buffer: []const T,
        height: usize,
        width: usize,
        index: usize = 0,
        line: usize = 0,
        cursor: usize = 0,

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
            cursor: usize = 0,
            validIndex: ?usize = null,
        };

        pub fn next(self: *Self) ?SchematicNumber {
            const result = self.peek() orelse return null;
            self.index = result.end;
            self.line = result.line;
            self.cursor = result.cursor;
            return result;
        }

        pub fn peek(self: *Self) ?SchematicNumber {
            var cursor = self.cursor;
            var line = self.line;
            var sn: ?SchematicNumber = null;

            for ((self.index)..(self.buffer.len)) |i| {
                const c = self.buffer[i];
                // std.debug.print("{c}", .{c});
                switch (c) {
                    '0'...'9' => {
                        if (sn == null) {
                            sn = SchematicNumber{ .start = i, .line = line };

                            // west
                            const directions = [_]Direction{ Direction.nw, Direction.w, Direction.sw };
                            const vi = self.getValidIndices(i, &directions);
                            std.debug.print("w {c}, i:{d}, vi: {?}\n", .{ c, i, vi });
                            if (vi != null) {
                                sn.?.validIndex = vi;
                            }
                        }

                        // if (sn.?.validIndex == null) {
                        // north, south
                        const directions = [_]Direction{ Direction.n, Direction.s };
                        const vi = self.getValidIndices(i, &directions);
                        std.debug.print("ns0 {c}, i:{d}, vi: {?}\n", .{ c, i, vi });
                        if (vi != null) {
                            sn.?.validIndex = vi;
                        }
                        // }
                    },
                    else => {
                        if (sn != null) {
                            // we have a number
                            sn.?.end = i;
                            var nSlice = self.buffer[sn.?.start..sn.?.end];
                            // std.debug.print("{s}", .{nSlice});
                            sn.?.value = std.fmt.parseUnsigned(usize, nSlice, 10) catch 0;
                            std.debug.print("{d}\n", .{sn.?.value});

                            if (sn.?.validIndex == null) {
                                // // east
                                // const directions = [_]Direction{ Direction.ne, Direction.e, Direction.se };
                                // north, south
                                // const directions = [_]Direction{ Direction.n, Direction.s };
                                const directions = [_]Direction{ Direction.n, Direction.s, Direction.ne, Direction.e, Direction.se };
                                const vi = self.getValidIndices(i, &directions);
                                // std.debug.print("e {c}, i:{d}, vi: {?}\n", .{ c, i, vi });
                                // std.debug.print("ns {c}, i:{d}, vi: {?}\n", .{ c, i, vi });
                                std.debug.print("ns/e {c}, i:{d}, vi: {?}\n", .{ c, i, vi });
                                if (vi != null) {
                                    sn.?.validIndex = vi;
                                }
                            }

                            return sn;
                        }

                        if (c == '\n') {
                            line += 1;
                            cursor = 0;
                        }
                    },
                }

                cursor += 1;
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
        pub fn getValidIndices(self: *Self, index: usize, directions: []const Direction) ?usize {
            std.debug.print("$$ {any}\n", .{directions});

            for (directions) |d| {
                std.debug.print("!!d:{}\n", .{d});

                const v = self.getValidDirectionIndex(index, d);
                std.debug.print("index: {d}, v:{?}, d:{}\n", .{ index, v, d });

                if (v != null) {
                    const vi = self.isSymbol(v.?, d);

                    if (vi != null) {
                        std.debug.print("index: {d}, vi:{?}, d:{}\n", .{ index, vi, d });
                        return vi;
                    }
                }
            }

            return null;
        }

        pub fn getValidDirectionIndex(self: *Self, index: usize, direction: Direction) ?usize {
            const line = index / self.width;
            if (line == 0 and direction.isNorth()) {
                std.debug.print("^^N", .{});
                return null;
            }

            if (line == self.height and direction.isSouth()) {
                std.debug.print("^^S", .{});
                return null;
            }

            const cursor = index % self.width;
            if (cursor == 0 and direction.isWest()) {
                std.debug.print("^^W", .{});
                return null;
            }

            if (cursor == self.width and direction.isEast()) {
                std.debug.print("^^E", .{});
                return null;
            }

            return switch (direction) {
                Direction.ne => index - self.width - 1,
                Direction.n => index - self.width,
                Direction.nw => index - self.width - 1,
                Direction.e => index - 1,
                Direction.w => index - 1,
                Direction.se => index + self.width - 1,
                Direction.s => index + self.width,
                Direction.sw => index + self.width - 1,
            };
        }

        /// finds valid symbols
        pub fn isSymbol(self: *Self, index: usize, direction: Direction) ?usize {
            // const validIndex = self.getValidDirectionIndex(index, direction);
            // if (validIndex == null) {
            //     return null;
            // }

            // const c = self.buffer[validIndex.?];
            const c = self.buffer[index];
            // std.debug.print("@@index: {d}, vi: {d}, c: {c}\n", .{ index, validIndex.?, c });
            std.debug.print("@@index: {d}, c: {c}, d: {d}\n", .{ index, c, c });

            return switch (c) {
                46 => null,
                10 => null,
                48...57 => null,
                else => {
                    // std.debug.print("#index: {d}, c: {c}, validIndex:{?}, d:{}\n", .{ index, c, validIndex, direction });
                    std.debug.print("#index: {d}, c: {c}, d:{}\n", .{ index, c, direction });
                    return index;
                },
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
