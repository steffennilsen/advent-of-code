const std = @import("std");
const data = @embedFile("./4");
const test_data = @embedFile("./4.test");

const data_ncount_winning = 10;
const data_ncount_playing = 25;
const test_ncount_winning = 5;
const test_ncount_playing = 8;

pub fn main() !void {
    var lines = std.mem.tokenize(u8, test_data, "\n");
    _ = lines;
}

fn GameIterator(comptime T: type) type {
    return struct {
        index: usize = 0,
        buffer: []const T,
        ncount_playing: usize,
        ncount_winning: usize,

        const Self = @This();

        const Game = struct {
            id: usize,
            index_start: usize,
            index_end: usize,

            const winning = [Self]usize;
            const playing = [Self]usize;
        };

        pub fn next(self: *Self) ?usize {
            _ = self;
            return null;
        }

        pub fn peek(self: *Self) !?usize {
            const rest_slice = self.buffer[self.index..self.buffer.len];
            const id_index_end = std.mem.indexOf(T, rest_slice, ":").?;
            const rest_id_slice = self.buffer[self.index..id_index_end];
            const id_index_start = std.mem.lastIndexOf(T, rest_id_slice, " ").? + 1;
            const id_slice = self.buffer[id_index_start..id_index_end];
            std.debug.print("id_slice: [{s}]\n", .{id_slice});
            const id = try std.fmt.parseUnsigned(T, id_slice, 10);
            std.debug.print("id: [{d}]\n", .{id});

            return null;
        }

        pub fn reset(self: *Self) void {
            self.index = 0;
        }
    };
}

test "p1" {
    comptime var it = GameIterator(u8){
        .buffer = test_data,
        .ncount_playing = test_ncount_playing,
        .ncount_winning = test_ncount_winning,
    };

    _ = try it.peek();
}
