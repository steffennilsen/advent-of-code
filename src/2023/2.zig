const std = @import("std");
const data = @embedFile("./2");

pub fn main() !void {
    var lines = std.mem.tokenize(u8, data, "\n");
    var sumP1: usize = 0;

    while (lines.next()) |line| {
        const game = try parseGame(line);
        sumP1 = sumP1 + game.p1;
    }

    std.debug.print("part 1: {d}\n", .{sumP1});
}

const GameStats = struct {
    p1: usize,
    p2: usize,
};

const GameSet = struct {
    red: usize,
    green: usize,
    blue: usize,
};

const MAX_DICES = GameSet{
    .red = 12,
    .green = 13,
    .blue = 14,
};

fn parseGame(line: []const u8) !GameStats {

    // finding space and colon between game ids, then get the game id
    const idStart = std.mem.indexOf(u8, line, " ");
    const idEnd = std.mem.indexOf(u8, line, ":");
    const idSlice = line[(idStart.? + 1)..idEnd.?];
    const id = try std.fmt.parseInt(usize, idSlice, 10);

    var gameStats = GameStats{ .p1 = id, .p2 = 0 };

    var setIt = std.mem.splitSequence(u8, line[(idEnd.? + 1)..line.len], ";");
    while (setIt.next()) |setSlice| {
        var setDices = GameSet{
            .blue = 0,
            .green = 0,
            .red = 0,
        };

        var diceIt = std.mem.splitSequence(u8, setSlice, ",");
        while (diceIt.next()) |diceSlice| {
            const trimmed = std.mem.trim(u8, diceSlice, " ");
            var qIt = std.mem.splitSequence(u8, trimmed, " ");
            const qSplice: ?[]const u8 = qIt.next();
            const cSplice: ?[]const u8 = qIt.next();

            // sanity check
            std.debug.assert(qSplice != null);
            std.debug.assert(cSplice != null);

            const q = try std.fmt.parseUnsigned(u8, qSplice.?, 10);

            if (std.mem.eql(u8, cSplice.?, "red")) {
                setDices.red = q;
            } else if (std.mem.eql(u8, cSplice.?, "green")) {
                setDices.green = q;
            } else if (std.mem.eql(u8, cSplice.?, "blue")) {
                setDices.blue = q;
            } else {
                unreachable;
            }
        }

        if (setDices.blue > MAX_DICES.blue or setDices.green > MAX_DICES.green or setDices.red > MAX_DICES.red) {
            gameStats.p1 = 0;
        }
    }

    return gameStats;
}

test "p1_game_1" {
    const line: []const u8 = "Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green";
    const actual = comptime try parseGame(line);
    try std.testing.expectEqual(1, actual.p1);
}

test "p1_game_2" {
    const line: []const u8 = "Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue";
    const actual = comptime try parseGame(line);
    try std.testing.expectEqual(2, actual.p1);
}

test "p1_game_3" {
    const line: []const u8 = "Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red";
    const actual = comptime try parseGame(line);
    try std.testing.expectEqual(0, actual.p1);
}

test "p1_game_4" {
    const line: []const u8 = "Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red";
    const actual = comptime try parseGame(line);
    try std.testing.expectEqual(0, actual.p1);
}

test "p1_game_5" {
    const line: []const u8 = "Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green";
    const actual = comptime try parseGame(line);
    try std.testing.expectEqual(5, actual.p1);
}
