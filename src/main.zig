const std = @import("std");

const day01 = @import("day01.zig");
const day02 = @import("day02.zig");
const day03 = @import("day03.zig");
const day04 = @import("day04.zig");

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    //try day01.run(allocator);
    //try day02.run();
    //try day03.run(allocator);
    try day04.run(allocator);
}
