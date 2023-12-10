pub fn Iterator(comptime T: type) type {
    return struct {
        buffer: []const T,
        index: usize = 0,

        const Self = @This();

        pub fn next(self: *Self) !?usize {
            const result = 1;
            self.index = 4;
            return result;
        }
    };
}

test "iterator error" {
    const buffer: []const u8 = "foobar";
    var it = Iterator(u8){ .buffer = buffer };
    _ = it;
}
