const std = @import("std");
const data: []const u8 = @embedFile("./3");
const testData: []const u8 = @embedFile("./3.test");

pub fn main() !void {
    const stats = getDataStats(data);
    const slice1 = data[0..stats.lineWidth];
    const slice2 = data[stats.lineWidth..(stats.lineWidth * 2)];

    std.debug.print("lineCount: {d}\n", .{stats.lineCount});
    std.debug.print("lineWidth (including \\n): {d}\n", .{stats.lineWidth});

    std.debug.print("###\n", .{});
    std.debug.print("{s}", .{slice1});
    std.debug.print("{s}", .{slice2});
    std.debug.print("###\n", .{});
}

const DataStats = struct {
    lineCount: usize,
    lineWidth: usize,
};

fn getDataStats(buffer: []const u8) DataStats {
    return DataStats{
        .lineCount = std.mem.count(u8, buffer, "\n") + 1,
        .lineWidth = std.mem.indexOf(u8, buffer, "\n").? + 1,
    };
}

// using std.mem.TokenIterator as example
fn SchematicIterator(comptime T: type, height: usize, width: usize) type {
    return struct {
        buffer: []const T,
        index: usize = 0,
        height: height,
        width: width,

        const Self = @This();

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
            var index = self.index;
            var line = std.math.ceil(index / self.width);
            var cursor = index % self.width;
            const slice = self.rest();
            var sn: ?SchematicNumber = null;

            for (slice) |c| {
                switch (c) {
                    '\n' => {
                        line += 1;
                    },
                    '.' => {},
                    '0'...'9' => {
                        if (sn == null) {
                            sn = SchematicNumber{
                                .start = index,
                                .line = line,
                            };
                        }
                    },
                    else => {},
                }

                index += 1;
                cursor = index % self.width;
            }
        }

        pub fn rest(self: *Self) []const T {
            return self.buffer[(self.index)..(self.buffer.len)];
        }

        pub fn reset(self: *Self) void {
            self.index = 0;
        }

        pub fn isSymbol(c: T) bool {
            switch (c) {
                '.' or '0'...'9' => return false,
                else => return true,
            }
        }

        pub fn getInBoundsIndices(self: *Self, index: usize) []usize {
            const line = std.math.ceil(index / self.width);
            const cursor = index % self.width;
            const indices: [8]usize = {};
            var i = 0;

            if (line > 0) {
                if (cursor > 0) {
                    // ne
                    indices[i] = self.buffer[index - self.width - 1];
                    i += 1;
                }

                // n
                indices[i] = self.buffer[index - self.width];
                i += 1;

                if (cursor < self.width) {
                    // nw
                    indices[i] = self.buffer[index - self.width + 1];
                    i += 1;
                }
            }

            if (cursor > 0) {
                // w
            }

            if (cursor < self.width) {
                // e
            }

            if (line < self.height) {
                // se
                if (cursor > 0) {
                    // ne
                    indices[i] = self.buffer[index - self.width - 1];
                    i += 1;
                }
                // s
                // se
            }

            return indices[0..i];
        }

        pub fn findSymbol(self: *Self, index: usize) ?usize {
            _ = index;
            _ = self;
        }
    };
}

test "getDataStats" {
    const actual = comptime getDataStats(testData);
    try std.testing.expectEqual(10, actual.lineCount);
    try std.testing.expectEqual(11, actual.lineWidth);
}

test "part1" {}
