const std = @import("std");

pub fn main() !void {
    const buffer: []const u8 = "Hello World!";
    std.debug.print("main.buffer> [{s}]\n", .{buffer});

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const s = try Struct(u8).init(allocator, buffer);
    std.debug.print("main.s> [{s}]\n", .{s.list.items});
}

fn Struct(comptime T: type) type {
    return struct {
        allocator: std.mem.Allocator,
        list: std.ArrayList(T),

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator, buffer: []const T) !Self {
            var list = std.ArrayList(T).init(allocator);
            try list.appendSlice(buffer);
            std.debug.print("Struct.init> [{s}]\n", .{list.items});

            return Self{
                .allocator = allocator,
                .list = list,
            };
        }

        pub fn deinit(self: *Self) void {
            self.list.deinit();
        }
    };
}
