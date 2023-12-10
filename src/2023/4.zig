const std = @import("std");
const TokenIterator = std.mem.TokenIterator;
const data = @embedFile("./4");
const test_data = @embedFile("./4.test");

pub fn main() !void {
    var lines = std.mem.tokenize(u8, test_data, "\n");
    _ = lines;
}

pub fn ParseGamesIterator(comptime T: type) type {
    return struct {
        allocator: *std.mem.Allocator,
        buffer: []const T,
        line_it: std.mem.TokenIterator(T, .any),

        const Self = @This();

        pub const Game = struct {
            id: usize,
            playing: std.ArrayList(usize),
            winning: std.ArrayList(usize),
        };

        pub fn next(self: *Self) !?Game {
            const result = try self.peek() orelse return null;
            _ = self.line_it.next();
            return result;
        }

        pub fn peek(self: *Self) !?Game {
            const line = self.line_it.peek() orelse return null;

            const id_index_end = std.mem.indexOf(T, line, ":").?;
            const rest_id_slice = line[0..id_index_end];
            const id_index_start = std.mem.lastIndexOf(T, rest_id_slice, " ").? + 1;
            const id_slice = line[id_index_start..id_index_end];
            const id = try std.fmt.parseUnsigned(T, id_slice, 10);

            const pipe_index = std.mem.indexOf(T, line, "|").?;
            const winning_slice = std.mem.trim(T, line[(id_index_end + 1)..pipe_index], " ");
            const playing_slice = std.mem.trim(T, line[(pipe_index + 1)..line.len], " ");

            var winning_it = std.mem.splitSequence(T, winning_slice, " ");
            var playing_it = std.mem.splitSequence(T, playing_slice, " ");
            var winning = std.ArrayList(usize).init(self.allocator.*);
            var playing = std.ArrayList(usize).init(self.allocator.*);

            while (winning_it.next()) |n| {
                var trimmed = std.mem.trim(T, n, " ");
                if (trimmed.len == 0) {
                    continue;
                }

                const parsed = try std.fmt.parseUnsigned(usize, trimmed, 10);
                try winning.append(parsed);
            }

            while (playing_it.next()) |n| {
                var trimmed = std.mem.trim(T, n, " ");
                if (trimmed.len == 0) {
                    continue;
                }

                const parsed = try std.fmt.parseUnsigned(usize, trimmed, 10);
                try playing.append(parsed);
            }

            return Game{
                .id = id,
                .winning = winning,
                .playing = playing,
            };
        }

        pub fn reset(self: *Self) void {
            self.index = 0;
            self.line_it.reset();
        }
    };
}

pub fn getGames(buffer: []const u8) void {
    _ = buffer;
    var arena: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    var line_it = std.mem.tokenize(u8, test_data, "\n");
    var it = ParseGamesIterator(u8){ .buffer = test_data, .line_it = line_it, .allocator = &allocator };

    while (try it.next()) |g| {
        std.debug.print("{any}\n", .{g});
    }
}

test "p1" {
    const games = getGames(test_data);
    _ = games;
}
