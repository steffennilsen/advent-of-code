const std = @import("std");
const data = @embedFile("./2");

pub fn main() !void {
    var lines = std.mem.tokenize(u8, data, "\n");
    var idSum: usize = 0;

    while (lines.next()) |line| {
        idSum = idSum + try parseGame(line);
    }

    std.debug.print("part 1: {d}\n", .{idSum});
}

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

fn parseGame(line: []const u8) !usize {
    // finding space and colon between game ids, then get the game id
    const idStart = std.mem.indexOf(u8, line, " ");
    const idEnd = std.mem.indexOf(u8, line, ":");
    const idSlice = line[(idStart.? + 1)..idEnd.?];
    const id = try std.fmt.parseInt(usize, idSlice, 10);
    std.debug.print("{d}]\n", .{id});

    var setIt = std.mem.splitSequence(u8, line[(idEnd.? + 1)..line.len], ";");
    while (setIt.next()) |setSlice| {
        var setDices = GameSet{
            .blue = 0,
            .green = 0,
            .red = 0,
        };
        // std.debug.print("set: {s}\n", .{setSlice});
        var diceIt = std.mem.splitSequence(u8, setSlice, ",");
        std.debug.print("dice: ", .{});

        while (diceIt.next()) |diceSlice| {
            // std.debug.print("{s}", .{diceSlice});
            const trimmed = std.mem.trim(u8, diceSlice, " ");
            var qIt = std.mem.splitSequence(u8, trimmed, " ");
            const qSplice: ?[]const u8 = qIt.next();
            const cSplice: ?[]const u8 = qIt.next();

            // sanity check
            std.debug.assert(qSplice != null);
            std.debug.assert(cSplice != null);

            const q = try std.fmt.parseUnsigned(u8, qSplice.?, 10);

            if (std.mem.eql(u8, cSplice.?, "red")) {
                setDices.red = setDices.red + q;
            } else if (std.mem.eql(u8, cSplice.?, "green")) {
                setDices.green = setDices.green + q;
            } else if (std.mem.eql(u8, cSplice.?, "blue")) {
                setDices.blue = setDices.blue + q;
            } else {
                unreachable;
            }

            // std.debug.print("{d}/{s},", .{ q, cSplice.? });
        }
        std.debug.print("{}", .{setDices});
        std.debug.print("\n", .{});

        if (setDices.blue > MAX_DICES.blue or setDices.green > MAX_DICES.green or setDices.red > MAX_DICES.red) {
            return 0;
        }
    }

    std.debug.print("\n", .{});
    return id;
}
