const std = @import("std");
const data = @embedFile("./1");

pub fn main() !void {
    var lines = std.mem.tokenize(u8, data, "\n");
    var sum: u64 = 0;

    while (lines.next()) |line| {
        sum = sum + try parseLine(line);
    }

    std.debug.print("{d}\n", .{sum});
}

pub fn parseLine(line: []const u8) !u32 {
    var digits = [_]u8{ 0, 0 };

    for (line) |c| {
        if (std.ascii.isDigit(c)) {
            if (digits[0] == 0) {
                digits[0] = c;
            }
            digits[1] = c;
        }
    }

    return std.fmt.parseInt(u32, &[_]u8{ digits[0], digits[1] }, 10);
}

test "line1" {
    const line: []const u8 = "1abc2";
    const actual = comptime try parseLine(line);
    try std.testing.expectEqual(12, actual);
}

test "line2" {
    const line: []const u8 = "pqr3stu8vwx";
    const actual = comptime try parseLine(line);
    try std.testing.expectEqual(38, actual);
}

test "line3" {
    const line: []const u8 = "a1b2c3d4e5f";
    const actual = comptime try parseLine(line);
    try std.testing.expectEqual(15, actual);
}

test "line4" {
    const line: []const u8 = "treb7uchet";
    const actual = comptime try parseLine(line);
    try std.testing.expectEqual(77, actual);
}
