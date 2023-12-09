const std = @import("std");
const data: []const u8 = @embedFile("./3");
const testData: []const u8 = @embedFile("./3.test");

const dataSize: usize = 140;
const testSize: usize = 10;

pub fn main() !void {
    var sumPart1: usize = 0;
    var sumPart2: usize = 0;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const Mapped = std.AutoArrayHashMap(usize, std.ArrayList(usize));
    var map = Mapped.init(allocator);
    defer map.deinit();
    // const map = std.AutoArrayHashMap(usize, std.ArrayList(usize)).init(allocator);

    var it = SchemaScanner(u8, data, dataSize);
    while (it.next()) |n| {
        if (n.valid == null) {
            // std.debug.print("[{d}:{d}]: {d}\n", .{ n.line, n.cursor, n.value });
        } else {
            // std.debug.print("[{d}:{d}]: {d} {c}\n", .{ n.line, n.cursor, n.value, n.valid.?.symbol });
            sumPart1 += n.value;

            if (n.valid.?.symbol == '*') {
                // std.debug.print("[{d}:{d}]: {d} {c} {d}\n", .{ n.line, n.cursor, n.value, n.valid.?.symbol, n.valid.?.index });
                const key = n.valid.?.index;

                const v = try map.getOrPut(key);
                if (!v.found_existing) {
                    // std.debug.print("a {d}\n", .{key});
                    var list = std.ArrayList(usize).init(allocator);
                    v.value_ptr.* = list;
                    // try map.put(n.valid.?.index, list);
                }

                // std.debug.print("b k {}] len {any}\n", .{ key, v.value_ptr.*.items });
                try v.value_ptr.*.append(n.value);
                // std.debug.print("c k {}] len {any}\n", .{ key, v.value_ptr.*.items });
                // std.debug.print("[{d}:{d}]: {d} {c} {d}\n", .{ n.line, n.cursor, n.value, n.valid.?.symbol, v.value_ptr.*.items.len });
            }
        }
    }

    var it2 = map.iterator();
    while (it2.next()) |e| {
        const v: std.ArrayList(usize) = e.value_ptr.*;
        var sum: usize = 0;
        if (v.items.len == 2) {
            sum = v.items[0] * v.items[1];
            sumPart2 += sum;
        }

        // std.debug.print("d: k {any} sum {any}\n", .{ k, sum });
    }

    std.debug.print("part 1: {d}\n", .{sumPart1});
    std.debug.print("part 2: {d}\n", .{sumPart2});
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
            symbol: T,
            index: usize = 0,
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

            if (sn != null) {
                // end of file, but we have a number waiting
                // just copying above for now
                sn.?.end = self.buffer.len;
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
                    ss = self.peekSymbolMultiple(sn.?.end - 1, &NORTH_SOUTH_CENTER);
                }

                sn.?.valid = ss;
                return sn;
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
            const cIndex: isize = @intCast(index);
            const size: isize = @intCast(self.size);

            const peekIndex: isize = switch (d) {
                Direction.ne => cIndex - size - 1,
                Direction.n => cIndex - size - 1,
                Direction.nw => cIndex - size - 2,
                Direction.e => cIndex + 1,
                Direction.c => cIndex,
                Direction.w => cIndex - 1,
                Direction.se => cIndex + size + 2,
                Direction.s => cIndex + size + 1,
                Direction.sw => cIndex + size,
            };

            if (peekIndex < 0 or peekIndex > self.buffer.len - 1) {
                return null;
            }
            const cPeekIndex: usize = @intCast(peekIndex);

            const c = self.buffer[cPeekIndex];
            // std.debug.print("{d}:{d} '{c}' {}\n", .{ index, cPeekIndex, c, d });
            return switch (c) {
                '\n' => null,
                '.' => null,
                '0'...'9' => null,
                else => SchemaSymbol{ .index = cPeekIndex, .symbol = c },
            };
        }

        pub fn reset(self: *Self) ?SchemaNumber {
            self.index = 0;
        }
    };
}
