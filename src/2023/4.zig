const std = @import("std");
const TokenIterator = std.mem.TokenIterator;
const data = @embedFile("./4");
const test_data = @embedFile("./4.test");

pub fn main() !void {
    var lines = std.mem.tokenize(u8, test_data, "\n");
    _ = lines;
}

const Game = struct {
    id: usize,
    start: usize,
    end: usize,
    playing: [25]usize,
    winning: [10]usize,
};

pub fn GameIterator(comptime T: type) type {
    return struct {
        buffer: []const T,
        index: usize = 0,
        game: usize = 0,

        const Self = @This();

        pub fn next(self: *Self) !?Game {
            const result = try self.peek() orelse return null;
            std.debug.print("buffer.len: {d}\n", .{self.buffer.len});
            // std.debug.print("self.index: {} {d}, result.end: {} {d}\n", .{ @TypeOf(self.index), self.index, @TypeOf(result.end), result.end });
            self.index = result.end;
            self.game += 1;
            std.debug.print("index: {d} char: {d}[{c}]\n", .{ self.index, self.buffer[self.index], self.buffer[self.index] });
            return result;
        }

        pub fn peek(self: *Self) !?Game {
            const start = self.index;
            // const end = std.mem.indexOf(T, self.buffer[start..self.buffer.len], "\n") orelse self.buffer.len - 1;
            const end = (self.game + 1) * 48; // 116 49

            if (end > self.buffer.len) {
                return null;
            }

            std.debug.print("start: {d}[{c}], end: {d}[{c}]\n", .{ start, self.buffer[start], end, self.buffer[end] });
            const line = self.buffer[start..end];

            std.debug.print("line: [{s}]\n", .{line});

            const id_index_end = std.mem.indexOf(T, line, ":").?;
            const rest_id_slice = line[0..id_index_end];
            const id_index_start = std.mem.lastIndexOf(T, rest_id_slice, " ").? + 1;
            const id_slice = line[id_index_start..id_index_end];
            const id = try std.fmt.parseUnsigned(T, id_slice, 10);

            // std.debug.print("id = {d}\n", .{id});

            const pipe_index = std.mem.indexOf(T, line, "|").?;
            const winning_slice = std.mem.trim(T, line[(id_index_end + 1)..pipe_index], " ");
            const playing_slice = std.mem.trim(T, line[(pipe_index + 1)..line.len], " ");

            // std.debug.print("id = {d} [{s} | {s}]\n", .{ id, winning_slice, playing_slice });

            var i: usize = 0;
            var winning_it = std.mem.splitSequence(T, winning_slice, " ");
            var playing_it = std.mem.splitSequence(T, playing_slice, " ");
            var winning: [10]usize = [_]usize{0} ** 10;
            var playing: [25]usize = [_]usize{0} ** 25;

            while (winning_it.next()) |n| {
                var trimmed = std.mem.trim(T, n, " ");
                if (trimmed.len == 0) {
                    continue;
                }

                winning[i] = try std.fmt.parseUnsigned(usize, trimmed, 10);
                i += 1;
            }

            i = 0;
            while (playing_it.next()) |n| {
                var trimmed = std.mem.trim(T, n, " ");
                if (trimmed.len == 0) {
                    continue;
                }

                playing[i] = try std.fmt.parseUnsigned(usize, trimmed, 10);
                i += 1;
            }

            // std.debug.print("id = {d} [{any} | {any}]\n", .{ id, winning, playing });

            return Game{
                .id = id,
                .winning = winning,
                .playing = playing,
                .start = start,
                .end = end,
            };
        }

        pub fn reset(self: *Self) void {
            self.index = 0;
        }
    };
}

test "p1" {
    var it = GameIterator(u8){ .buffer = test_data };

    while (try it.next()) |g| {
        std.debug.print("{}\n", .{g});
    }
}
