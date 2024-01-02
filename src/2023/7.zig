const std = @import("std");

const Errors = error{
    ParseError,
};

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
    bid: usize,
    cards: [5]u8,
    hand: Hand,
};

fn parseCard(c: u8) u8 {
    return switch (c) {
        '0'...'9' => c - '0',
        'T' => 10,
        'J' => 10,
        'Q' => 10,
        'K' => 10,
        'A' => 10,
        else => 0,
    };
}

fn cardsToHand(cards: [5]u8) Hand {
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
        4 => Hand.FiveOfAKind,
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

fn comparePlay(comptime ctx: void, a: Play, b: Play) bool {
    _ = ctx;
    if (a.hand != b.hand) {
        return @intFromEnum(a.hand) > @intFromEnum(b.hand);
    }

    for (0..5) |i| {
        if (a.cards[i] != b.cards[i]) {
            return parseCard(a.cards[i]) < parseCard(b.cards[i]);
        }
    }

    return false;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer gpa.deinit();
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    var allocator = arena.allocator();
    _ = allocator;
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

fn parseBuffer(allocator: std.mem.Allocator, buffer: []const u8) !std.ArrayList(Play) {
    var plays = std.ArrayList(Play).init(allocator);

    var i: usize = 0;
    var it = std.mem.tokenize(u8, buffer, "\n");
    while (it.next()) |line| : (i += 1) {
        var it2 = std.mem.tokenize(u8, line, " ");
        const cards_slice: []const u8 = it2.next() orelse return Errors.ParseError;
        var cards: [5]u8 = undefined;
        std.mem.copy(u8, &cards, cards_slice);
        const hand = cardsToHand(cards);

        const bid_slice = it2.next() orelse return Errors.ParseError;
        const bid = try std.fmt.parseUnsigned(u32, bid_slice, 10);

        const play = Play{
            .bid = bid,
            .cards = cards,
            .hand = hand,
        };
        try plays.append(play);
    }

    return plays;
}

test "p1_1" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    const buffer = try readFile(allocator, "src/2023/7.test");
    const plays = try parseBuffer(allocator, buffer);
    defer plays.deinit();

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
    const plays = try parseBuffer(allocator, buffer);
    defer plays.deinit();

    std.mem.sort(Play, plays.items, {}, comparePlay);

    {
        const play: Play = plays.items[0];
        try std.testing.expect(std.mem.eql(u8, "T55J5", &play.cards));
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
