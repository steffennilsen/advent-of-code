const std = @import("std");
const data = @embedFile("./2");

pub fn main() !void {
    var lines = std.mem.tokenize(u8, data, "\n");
    var idSum: usize = 0;

    while (lines.next()) |line| {
        idSum = idSum + try parseGame(line);
    }
}

const Dice = enum { red, green, blue };
const GameSet = union(Dice) {
    red: usize,
    green: usize,
    blue: usize,
};

fn parseGame(line: []const u8) !usize {
    // finding space and colon between game ids, then get the game id
    const idStart = std.mem.indexOf(u8, line, " ");
    const idEnd = std.mem.indexOf(u8, line, ":");
    const idSlice = line[(idStart.? + 1)..idEnd.?];
    const id = try std.fmt.parseInt(usize, idSlice, 10);
    std.debug.print("{d}]", .{id});

    const setsSplice = line[idEnd.?..line.len];
    std.debug.print("{s}", .{setsSplice});

    std.debug.print("\n", .{});
    return 1;
}