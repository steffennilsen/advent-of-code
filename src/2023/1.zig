const std = @import("std");
const data = @embedFile("./1");

pub fn main() !void {
    var lines = std.mem.tokenize(u8, data, "\n");
    var sumPart1: u64 = 0;
    var sumPart2: u64 = 0;

    while (lines.next()) |line| {
        sumPart1 = sumPart1 + try parseLinePart1(line);
        sumPart2 = sumPart2 + try parseLinePart2(line);
    }

    std.debug.print("part 1: {d}\n", .{sumPart1});
    std.debug.print("part 2: {d}\n", .{sumPart2});
}

pub fn parseLinePart1(line: []const u8) !u32 {
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

const NUMBERS = [_][]const u8{
    "zero",
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
};

pub fn parseLinePart2(line: []const u8) !u32 {
    var digits = [_]u8{ 0, 0 };

    for (line, 0..) |c, cursorPos| {
        switch (c) {
            '0'...'9' => {
                if (digits[0] == 0) {
                    digits[0] = c;
                }

                digits[1] = c;
            },
            'a'...'z' => {
                numbers: for (NUMBERS, 0..) |haystack, n| {
                    if (cursorPos + haystack.len <= line.len) {
                        const end = @min(cursorPos + haystack.len, line.len);
                        const slice = line[cursorPos..end];

                        if (std.mem.eql(u8, haystack, slice)) {
                            if (digits[0] == 0) {
                                digits[0] = @intCast(n + 48);
                            }

                            digits[1] = @intCast(n + 48);
                            break :numbers;
                        }
                    }
                }
            },
            else => {},
        }
    }

    return std.fmt.parseInt(u32, &[_]u8{ digits[0], digits[1] }, 10);
}

test "p1_1abc2" {
    const line: []const u8 = "1abc2";
    const actual = comptime try parseLinePart1(line);
    try std.testing.expectEqual(12, actual);
}

test "p1_pqr3stu8vwx" {
    const line: []const u8 = "pqr3stu8vwx";
    const actual = comptime try parseLinePart1(line);
    try std.testing.expectEqual(38, actual);
}

test "p1_a1b2c3d4e5f" {
    const line: []const u8 = "a1b2c3d4e5f";
    const actual = comptime try parseLinePart1(line);
    try std.testing.expectEqual(15, actual);
}

test "p1_treb7uchet" {
    const line: []const u8 = "treb7uchet";
    const actual = comptime try parseLinePart1(line);
    try std.testing.expectEqual(77, actual);
}

test "p1_treb7uc0he4t" {
    const line: []const u8 = "treb7uc0he4t";
    const actual = comptime try parseLinePart1(line);
    try std.testing.expectEqual(74, actual);
}

test "p2_two1nine" {
    const line: []const u8 = "two1nine";
    const actual = comptime try parseLinePart2(line);
    try std.testing.expectEqual(29, actual);
}

test "p2_eightwothree" {
    const line: []const u8 = "eightwothree";
    const actual = comptime try parseLinePart2(line);
    try std.testing.expectEqual(83, actual);
}

test "p2_abcone2threexyz" {
    const line: []const u8 = "abcone2threexyz";
    const actual = comptime try parseLinePart2(line);
    try std.testing.expectEqual(13, actual);
}

test "p2_xtwone3four" {
    const line: []const u8 = "xtwone3four";
    const actual = comptime try parseLinePart2(line);
    try std.testing.expectEqual(24, actual);
}

test "p2_4nineeightseven2" {
    const line: []const u8 = "4nineeightseven2";
    const actual = comptime try parseLinePart2(line);
    try std.testing.expectEqual(42, actual);
}

test "p2_zoneight234" {
    const line: []const u8 = "zoneight234";
    const actual = comptime try parseLinePart2(line);
    try std.testing.expectEqual(14, actual);
}

test "p2_7pqrstsixteen" {
    const line: []const u8 = "7pqrstsixteen";
    const actual = comptime try parseLinePart2(line);
    try std.testing.expectEqual(76, actual);
}

test "p2_4fivehmg614five" {
    const line: []const u8 = "4fivehmg614five";
    const actual = comptime try parseLinePart2(line);
    try std.testing.expectEqual(45, actual);
}
