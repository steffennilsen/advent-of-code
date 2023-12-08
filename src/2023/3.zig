const std = @import("std");
const data: []const u8 = @embedFile("./3");
const testData: []const u8 = @embedFile("./3.test");

const dataSize: usize = 140;
const testSize: usize = 10;

pub fn main() !void {
    var sumPartNumbers: usize = 0;

    var it = SchemaScanner(u8, data, dataSize);
    while (it.next()) |n| {
        if (n.valid == null) {
            std.debug.print("[{d}:{d}]: {d}\n", .{ n.line, n.cursor, n.value });
            sumPartNumbers += n.value;
        } else {
            std.debug.print("[{d}:{d}]: {d} {c}\n", .{ n.line, n.cursor, n.value, n.valid.?.symbol });
        }
    }

    std.debug.print("part 1: {d}\n", .{sumPartNumbers});
}

pub fn SchemaScanner(comptime T: type, buffer: []const T, size: usize) SchemaIterator(T) {
    return .{
        .buffer = buffer,
        .index = 0,
        .size = size,
    };
}

pub fn SchemaIterator(comptime T: type) type {
    return struct {
        buffer: []const T,
        index: usize,
        size: usize,
        line: usize = 0,
        cursor: usize = 0,

        const Self = @This();

        const SchemaNumber = struct {
            start: usize = 0,
            end: usize = 0,
            line: usize = 0,
            cursor: usize = 0,
            value: usize = 0,
            slice: ?[]const T = null,
            valid: ?SchemaSymbol = null,
        };

        const SchemaSymbol = struct {
            index: usize = 0,
            symbol: T,
        };

        const WEST = [_]Direction{ Direction.nw, Direction.w, Direction.sw };
        const NORTH_SOUTH = [_]Direction{ Direction.n, Direction.s };
        const NORTH_SOUTH_CENTER = [_]Direction{ Direction.n, Direction.s, Direction.c };

        const Direction = enum {
            ne,
            n,
            nw,
            e,
            c,
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

        pub fn next(self: *Self) ?SchemaNumber {
            const result = self.peek() orelse return null;
            self.index = result.end;
            self.line = result.line;
            self.cursor = result.slice.?.len + result.cursor;
            return result;
        }

        pub fn nextValid(self: *Self) ?SchemaNumber {
            const result = self.peekValid() orelse return null;
            self.index = result.end;
            self.line = result.line;
            self.cursor = result.slice.?.len + result.cursor;
            return result;
        }

        pub fn peekValid(self: *Self) ?SchemaNumber {
            while (self.peek()) |n| {
                if (n.valid != null) {
                    return n;
                } else {
                    _ = self.next();
                }
            }

            return null;
        }

        pub fn peek(self: *Self) ?SchemaNumber {
            var line = self.line;
            var cursor = self.cursor;
            var sn: ?SchemaNumber = null;
            var ss: ?SchemaSymbol = null;

            for (self.index..self.buffer.len) |i| {
                const c = self.buffer[i];

                switch (c) {
                    '0'...'9' => {
                        if (sn == null) {
                            sn = SchemaNumber{ .start = i };
                            ss = self.peekSymbolMultiple(i, &WEST);
                        }

                        if (ss == null) {
                            ss = self.peekSymbolMultiple(i, &NORTH_SOUTH);
                        }
                    },
                    else => {
                        if (sn != null) {
                            // reached end of number
                            sn.?.end = i;
                            sn.?.line = line;

                            const slice = self.buffer[sn.?.start..sn.?.end];
                            sn.?.slice = slice;
                            sn.?.value = std.fmt.parseUnsigned(usize, slice, 10) catch std.math.maxInt(usize);

                            if (line == 0) {
                                sn.?.cursor = cursor - slice.len;
                            } else {
                                sn.?.cursor = cursor - slice.len - 1;
                            }

                            if (ss == null) {
                                ss = self.peekSymbolMultiple(i, &NORTH_SOUTH_CENTER);
                            }

                            sn.?.valid = ss;
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

        pub fn peekSymbolMultiple(self: *Self, index: usize, directions: []const Direction) ?SchemaSymbol {
            for (directions) |d| {
                const symbol = self.peekSymbol(index, d);
                if (symbol != null) {
                    return symbol;
                }
            }

            return null;
        }

        pub fn peekSymbol(self: *Self, index: usize, d: Direction) ?SchemaSymbol {
            const castedIndex = @as(isize, @intCast(index));
            const castedSize = @as(isize, @intCast(self.size));

            const peekIndex = switch (d) {
                Direction.ne => @max(0, castedIndex - castedSize - 1),
                Direction.n => @max(0, castedIndex - castedSize - 1),
                Direction.nw => @max(0, castedIndex - castedSize - 2),
                Direction.e => @min(self.buffer.len - 1, index + 1),
                Direction.c => index,
                Direction.w => @min(0, index - 1),
                Direction.se => @min(self.buffer.len - 1, index + self.size + 2),
                Direction.s => @min(self.buffer.len - 1, index + self.size + 1),
                Direction.sw => @min(self.buffer.len - 1, index + self.size + 1),
            };

            const c = self.buffer[peekIndex];
            // std.debug.print("{d}:{d} '{c}' {}\n", .{ index, peekIndex, c, d });
            return switch (c) {
                '\n' => null,
                '.' => null,
                '0'...'9' => null,
                else => SchemaSymbol{ .index = peekIndex, .symbol = c },
            };
        }

        pub fn reset(self: *Self) ?SchemaNumber {
            self.index = 0;
        }
    };
}

test "part1" {}
