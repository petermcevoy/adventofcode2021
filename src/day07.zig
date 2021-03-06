const std = @import("std");
const testing = std.testing;

const log = std.log.scoped(.day07);

pub fn run(allocator: std.mem.Allocator) anyerror!void {
    var input_str = @embedFile("../data/day07_input.txt");
    var it = std.mem.tokenize(u8, input_str, ",\n");
    var initial_positions = std.ArrayList(i32).init(allocator);
    defer initial_positions.deinit();
    while (it.next()) |v| try initial_positions.append(try std.fmt.parseInt(i32, v, 10));

    var fuel: i32 = 0;
    var part1_pos = findOptimalAlignmentPosition(initial_positions.items, &fuel, .part1);
    log.info("Part 1: pos {d}, fuel {d}", .{ part1_pos, fuel });

    var part2_pos = findOptimalAlignmentPosition(initial_positions.items, &fuel, .part2);
    log.info("Part 2: pos {d}, fuel {d}", .{ part2_pos, fuel });
}

const Method = enum { part1, part2 };

pub fn findOptimalAlignmentPosition(initial_positions: []const i32, fuel: *i32, comptime method: Method) i32 {
    var max_value: i32 = 0;
    for (initial_positions) |v| max_value = std.math.max(v, max_value);

    var best_pos: i32 = 0;
    var best_cost: i32 = std.math.maxInt(i32);
    var target: i32 = 0;
    while (target <= max_value) : (target += 1) {
        var cost: i32 = 0;

        switch (method) {
            .part1 => {
                for (initial_positions) |pos|
                    cost += std.math.absInt(target - pos) catch unreachable;
            },
            .part2 => {
                // Use triangular number to calculate new fuel
                // https://en.m.wikipedia.org/wiki/Triangular_number
                // 1 + 2 + ... + n = n*(n+1)/2

                for (initial_positions) |pos| {
                    var n = std.math.absInt(target - pos) catch unreachable;
                    cost += @divTrunc(n * (n + 1), 2);
                }
            },
        }
        if (cost < best_cost) {
            best_pos = target;
            best_cost = cost;
        }
    }

    fuel.* = best_cost;
    return best_pos;
}

test "part 1" {
    const example = [_]i32{ 16, 1, 2, 0, 4, 2, 7, 1, 2, 14 };

    var fuel: i32 = 0;
    var optimal_position = findOptimalAlignmentPosition(&example, &fuel, .part1);

    try testing.expectEqual(optimal_position, 2);
    try testing.expectEqual(fuel, 37);
}

test "part 2" {
    const example = [_]i32{ 16, 1, 2, 0, 4, 2, 7, 1, 2, 14 };

    var fuel: i32 = 0;
    var optimal_position = findOptimalAlignmentPosition(&example, &fuel, .part2);

    try testing.expectEqual(optimal_position, 5);
    try testing.expectEqual(fuel, 168);
}
