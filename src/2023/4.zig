const std = @import("std");
const TokenIterator = std.mem.TokenIterator;
const data = @embedFile("./4");
const test_data = @embedFile("./4.test");

pub fn main() !void {
    var arena: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    const games = try getGames(u8, &allocator, data);
    defer games.deinit();
    var sum_points: usize = 0;

    for (games.items) |g| {
        // std.debug.print("{d}> {any} | {any} | {any} | {d} \n", .{ g.id, g.winning.items, g.playing.items, g.played_winning.items, g.points });
        sum_points += g.points;
    }

    std.debug.print("part 1: {d}\n", .{sum_points});
}

const Game = struct {
    id: usize,
    playing: std.ArrayList(usize),
    winning: std.ArrayList(usize),
    played_winning: std.ArrayList(usize),
    points: usize,
};

pub fn ParseGamesIterator(comptime T: type) type {
    return struct {
        allocator: *std.mem.Allocator,
        buffer: []const T,
        line_it: std.mem.TokenIterator(T, .any),

        const Self = @This();

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
            var played_winning = std.ArrayList(usize).init(self.allocator.*);

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

                for (winning.items) |w| {
                    if (parsed == w) {
                        try played_winning.append(parsed);
                    }
                }
            }

            const points = switch (played_winning.items.len) {
                0 => 0,
                else => std.math.pow(usize, 2, played_winning.items.len - 1),
            };

            return Game{
                .id = id,
                .winning = winning,
                .playing = playing,
                .played_winning = played_winning,
                .points = points,
            };
        }

        pub fn reset(self: *Self) void {
            self.index = 0;
            self.line_it.reset();
        }
    };
}

pub fn getGames(comptime T: type, allocator: *std.mem.Allocator, buffer: []const u8) !std.ArrayListAligned(Game, null) {
    var games = std.ArrayList(Game).init(allocator.*);

    var line_it = std.mem.tokenize(T, buffer, "\n");
    var it = ParseGamesIterator(T){ .buffer = test_data, .line_it = line_it, .allocator = allocator };

    while (try it.next()) |g| {
        try games.append(g);
    }

    return games;
}

test "p1" {
    var arena: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    const games = try getGames(u8, &allocator, test_data);
    defer games.deinit();

    std.debug.print("\n", .{});

    for (games.items) |g| {
        std.debug.print("{d}> {any} | {any} | {any} | {d} \n", .{ g.id, g.winning.items, g.playing.items, g.played_winning.items, g.points });
    }
}
