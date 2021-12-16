const std = @import("std");

const day01 = @import("day01.zig");
const day02 = @import("day02.zig");
const day03 = @import("day03.zig");
const day04 = @import("day04.zig");
const day05 = @import("day05.zig");
const day06 = @import("day06.zig");
const day07 = @import("day07.zig");
const day08 = @import("day08.zig");
const day09 = @import("day09.zig");
const day10 = @import("day10.zig");
const day11 = @import("day11.zig");

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    //try day01.run(allocator);
    //try day02.run();
    //try day03.run(allocator);
    //try day04.run(allocator);
    //try day05.run(allocator);
    //try day06.run(allocator);
    //try day07.run(allocator);
    //try day08.run();
    //try day09.run();
    //try day10.run();
    try day11.run();
}
