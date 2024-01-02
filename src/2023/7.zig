const std = @import("std");

const Errors = error{
    ParseError,
};

const Part = enum { One, Two };

const Hand = enum(u8) {
    HighCard,
    OnePair,
    TwoPair,
    ThreeOfAKind,
    FullHouse,
    FourOfAKind,
    FiveOfAKind,
};

const Play = struct {
    bid_ranked: usize,
    bid: usize,
    cards: [5]u8,
    hand: Hand,
};

fn parseCardP1(c: u8) u8 {
    return switch (c) {
        '0'...'9' => c - '0',
        'T' => 10,
        'J' => 11,
        'Q' => 12,
        'K' => 13,
        'A' => 14,
        else => 0,
    };
}

fn parseCardP2(c: u8) u8 {
    return switch (c) {
        'J' => 1,
        '0'...'9' => c - '0',
        'T' => 10,
        'Q' => 12,
        'K' => 13,
        'A' => 14,
        else => 0,
    };
}

fn cardsToHandP1(cards: [5]u8) Hand {
    var dist = [_]u8{ 1, 0, 0, 0, 0 };
    var j: usize = 4;
    jloop: while (j > 0) : (j -= 1) {
        for (0..j) |k| {
            if (cards[j] == cards[k]) {
                dist[k] += 1;
                continue :jloop;
            }
        }

        dist[j] += 1;
    }

    std.mem.sort(u8, &dist, {}, comptime std.sort.desc(u8));

    var hand: Hand = switch (dist[0]) {
        5 => Hand.FiveOfAKind,
        4 => Hand.FourOfAKind,
        3 => blk: {
            if (dist[1] == 2) break :blk Hand.FullHouse;
            break :blk Hand.ThreeOfAKind;
        },
        2 => blk: {
            if (dist[1] == 2) break :blk Hand.TwoPair;
            break :blk Hand.OnePair;
        },
        else => Hand.HighCard,
    };

    return hand;
}

fn cardsToHandP2(cards: [5]u8) Hand {
    var dist = [_]u8{ 0, 0, 0, 0, 0 };
    var j: usize = 5;
    var jokers: u8 = 0;
    jloop: while (j > 0) : (j -= 1) {
        if (cards[j - 1] == 'J') {
            jokers += 1;
            continue :jloop;
        }

        for (0..j - 1) |k| {
            if (cards[j - 1] == cards[k]) {
                dist[k] += 1;
                continue :jloop;
            }
        }

        dist[j - 1] += 1;
    }

    std.mem.sort(u8, &dist, {}, comptime std.sort.desc(u8));
    dist[0] += jokers;

    var hand: Hand = switch (dist[0]) {
        5 => Hand.FiveOfAKind,
        4 => Hand.FourOfAKind,
        3 => blk: {
            if (dist[1] == 2) break :blk Hand.FullHouse;
            break :blk Hand.ThreeOfAKind;
        },
        2 => blk: {
            if (dist[1] == 2) break :blk Hand.TwoPair;
            break :blk Hand.OnePair;
        },
        else => Hand.HighCard,
    };

    return hand;
}

fn comparePlayP1(_: void, a: Play, b: Play) bool {
    if (a.hand != b.hand) {
        return @intFromEnum(a.hand) < @intFromEnum(b.hand);
    }

    for (0..5) |i| {
        if (a.cards[i] != b.cards[i]) {
            return parseCardP1(a.cards[i]) < parseCardP1(b.cards[i]);
        }
    }

    return false;
}

fn comparePlayP2(_: void, a: Play, b: Play) bool {
    if (a.hand != b.hand) {
        return @intFromEnum(a.hand) < @intFromEnum(b.hand);
    }

    for (0..5) |i| {
        if (a.cards[i] != b.cards[i]) {
            return parseCardP2(a.cards[i]) < parseCardP2(b.cards[i]);
        }
    }

    return false;
}

fn debugPrint(plays: std.ArrayList(Play)) void {
    for (plays.items, 0..) |play, i| {
        std.debug.print("{d}> cards: {s}, bid: {d}, p1: {d}, hand: {}\n", .{ (i + 1), play.cards, play.bid, play.p1, play.hand });
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    var allocator = arena.allocator();
    const stdout = std.io.getStdOut().writer();

    const buffer = try readFile(allocator, "src/2023/7");

    // PART 1
    var plays_p1 = try parseBuffer(allocator, buffer, Part.One);
    defer plays_p1.deinit();
    const p1 = sortAndSumBids(&plays_p1, Part.One);
    try stdout.print("Part 1: {d}\n", .{p1});

    // PART 2
    var plays_p2 = try parseBuffer(allocator, buffer, Part.Two);
    defer plays_p2.deinit();
    const p2 = sortAndSumBids(&plays_p2, Part.Two);
    try stdout.print("Part 2: {d}\n", .{p2});
}

fn readFile(allocator: std.mem.Allocator, sub_path: []const u8) ![]const u8 {
    var file = try std.fs.cwd().openFile(sub_path, .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    var reader = buffered.reader();

    const file_size = (try file.stat()).size;
    var buffer: []u8 = try allocator.alloc(u8, file_size);
    try reader.readNoEof(buffer);

    return buffer;
}

fn parseBuffer(allocator: std.mem.Allocator, buffer: []const u8, part: Part) !std.ArrayList(Play) {
    var plays = std.ArrayList(Play).init(allocator);

    var i: usize = 0;
    var it = std.mem.tokenize(u8, buffer, "\n");
    while (it.next()) |line| : (i += 1) {
        var it2 = std.mem.tokenize(u8, line, " ");
        const cards_slice: []const u8 = it2.next() orelse return Errors.ParseError;
        var cards: [5]u8 = undefined;
        std.mem.copy(u8, &cards, cards_slice);

        const hand = switch (part) {
            Part.One => cardsToHandP1(cards),
            Part.Two => cardsToHandP2(cards),
        };

        const bid_slice = it2.next() orelse return Errors.ParseError;
        const bid = try std.fmt.parseUnsigned(u32, bid_slice, 10);

        const play = Play{
            .bid_ranked = 0,
            .bid = bid,
            .cards = cards,
            .hand = hand,
        };
        try plays.append(play);
    }

    return plays;
}

pub fn sortAndSumBids(plays: *std.ArrayList(Play), part: Part) usize {
    switch (part) {
        Part.One => std.mem.sort(Play, plays.items, {}, comparePlayP1),
        Part.Two => std.mem.sort(Play, plays.items, {}, comparePlayP2),
    }

    var sum: usize = 0;
    for (0..plays.items.len) |i| {
        const bid_ranked = plays.items[i].bid * (i + 1);
        plays.items[i].bid_ranked = bid_ranked;
        sum += bid_ranked;
    }

    return sum;
}

test "p1_1" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    const buffer = try readFile(allocator, "src/2023/7.test");
    const plays = try parseBuffer(allocator, buffer, Part.One);
    defer plays.deinit();

    try std.testing.expectEqual(@as(usize, 5), plays.items.len);

    {
        const play: Play = plays.items[0];
        try std.testing.expect(std.mem.eql(u8, "32T3K", &play.cards));
        try std.testing.expectEqual(Hand.OnePair, play.hand);
    }

    {
        const play: Play = plays.items[1];
        try std.testing.expect(std.mem.eql(u8, "T55J5", &play.cards));
        try std.testing.expectEqual(Hand.ThreeOfAKind, play.hand);
    }

    {
        const play: Play = plays.items[2];
        try std.testing.expect(std.mem.eql(u8, "KK677", &play.cards));
        try std.testing.expectEqual(Hand.TwoPair, play.hand);
    }

    {
        const play: Play = plays.items[3];
        try std.testing.expect(std.mem.eql(u8, "KTJJT", &play.cards));
        try std.testing.expectEqual(Hand.TwoPair, play.hand);
    }

    {
        const play: Play = plays.items[4];
        try std.testing.expect(std.mem.eql(u8, "QQQJA", &play.cards));
        try std.testing.expectEqual(Hand.ThreeOfAKind, play.hand);
    }
}

test "p1_2" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    const buffer = try readFile(allocator, "src/2023/7.test");
    var plays = try parseBuffer(allocator, buffer, Part.One);
    defer plays.deinit();

    const sum = sortAndSumBids(&plays, Part.One);

    {
        const rank = 1;
        const play: Play = plays.items[rank - 1];
        try std.testing.expect(std.mem.eql(u8, "32T3K", &play.cards));
        try std.testing.expectEqual(Hand.OnePair, play.hand);
        try std.testing.expectEqual(@as(usize, 765), play.bid);
        try std.testing.expectEqual(@as(usize, 765 * rank), play.bid_ranked);
    }

    {
        const rank = 2;
        const play: Play = plays.items[rank - 1];
        try std.testing.expect(std.mem.eql(u8, "KTJJT", &play.cards));
        try std.testing.expectEqual(Hand.TwoPair, play.hand);
        try std.testing.expectEqual(@as(usize, 220), play.bid);
        try std.testing.expectEqual(@as(usize, 220 * rank), play.bid_ranked);
    }

    {
        const rank = 3;
        const play: Play = plays.items[rank - 1];
        try std.testing.expect(std.mem.eql(u8, "KK677", &play.cards));
        try std.testing.expectEqual(Hand.TwoPair, play.hand);
        try std.testing.expectEqual(@as(usize, 28), play.bid);
        try std.testing.expectEqual(@as(usize, 28 * rank), play.bid_ranked);
    }

    {
        const rank = 4;
        const play: Play = plays.items[rank - 1];
        try std.testing.expect(std.mem.eql(u8, "T55J5", &play.cards));
        try std.testing.expectEqual(Hand.ThreeOfAKind, play.hand);
        try std.testing.expectEqual(@as(usize, 684), play.bid);
        try std.testing.expectEqual(@as(usize, 684 * rank), play.bid_ranked);
    }

    {
        const rank = 5;
        const play: Play = plays.items[rank - 1];
        try std.testing.expect(std.mem.eql(u8, "QQQJA", &play.cards));
        try std.testing.expectEqual(Hand.ThreeOfAKind, play.hand);
        try std.testing.expectEqual(@as(usize, 483), play.bid);
        try std.testing.expectEqual(@as(usize, 483 * rank), play.bid_ranked);
    }

    {
        try std.testing.expectEqual(@as(usize, 6440), sum);
    }
}

test "p2_2" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    const buffer = try readFile(allocator, "src/2023/7.test");
    var plays = try parseBuffer(allocator, buffer, Part.Two);
    defer plays.deinit();

    const sum = sortAndSumBids(&plays, Part.Two);

    {
        const rank = 1;
        const play: Play = plays.items[rank - 1];
        try std.testing.expect(std.mem.eql(u8, "32T3K", &play.cards));
        try std.testing.expectEqual(Hand.OnePair, play.hand);
        try std.testing.expectEqual(@as(usize, 765), play.bid);
        try std.testing.expectEqual(@as(usize, 765 * rank), play.bid_ranked);
    }

    {
        const rank = 2;
        const play: Play = plays.items[rank - 1];
        try std.testing.expect(std.mem.eql(u8, "KK677", &play.cards));
        try std.testing.expectEqual(Hand.TwoPair, play.hand);
        try std.testing.expectEqual(@as(usize, 28), play.bid);
        try std.testing.expectEqual(@as(usize, 28 * rank), play.bid_ranked);
    }

    {
        const rank = 3;
        const play: Play = plays.items[rank - 1];
        try std.testing.expect(std.mem.eql(u8, "T55J5", &play.cards));
        try std.testing.expectEqual(Hand.FourOfAKind, play.hand);
        try std.testing.expectEqual(@as(usize, 684), play.bid);
        try std.testing.expectEqual(@as(usize, 684 * rank), play.bid_ranked);
    }

    {
        const rank = 4;
        const play: Play = plays.items[rank - 1];
        try std.testing.expect(std.mem.eql(u8, "QQQJA", &play.cards));
        try std.testing.expectEqual(Hand.FourOfAKind, play.hand);
        try std.testing.expectEqual(@as(usize, 483), play.bid);
        try std.testing.expectEqual(@as(usize, 483 * rank), play.bid_ranked);
    }

    {
        const rank = 5;
        const play: Play = plays.items[rank - 1];
        try std.testing.expect(std.mem.eql(u8, "KTJJT", &play.cards));
        try std.testing.expectEqual(Hand.FourOfAKind, play.hand);
        try std.testing.expectEqual(@as(usize, 220), play.bid);
        try std.testing.expectEqual(@as(usize, 220 * rank), play.bid_ranked);
    }

    {
        try std.testing.expectEqual(@as(usize, 5905), sum);
    }
}
