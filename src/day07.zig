const std = @import("std");
const testing = std.testing;
const assert = std.debug.assert;

const log = std.log.scoped(.day07);

pub fn run(allocator: *std.mem.Allocator) anyerror!void {
    var input_str = @embedFile("../data/day07_input.txt");
    var it = std.mem.tokenize(input_str, ",\n");
    var initial_positions = std.ArrayList(i32).init(allocator);
    defer initial_positions.deinit();
    while (it.next()) |v| try initial_positions.append(try std.fmt.parseInt(i32, v, 10));

    var fuel: i32 = 0;
    var part1_pos = findOptimalAlignmentPosition(initial_positions.items, &fuel);

    log.info("Part 1: pos {d}, fuel {d}", .{ part1_pos, fuel });
}

pub fn findOptimalAlignmentPosition(initial_positions: []const i32, fuel: *i32) i32 {
    var max_value: i32 = 0;
    for (initial_positions) |v| max_value = std.math.max(v, max_value);

    var best_pos: i32 = 0;
    var best_cost: i32 = std.math.maxInt(i32);
    var target: i32 = 0;
    while (target <= max_value) : (target += 1) {
        var cost: i32 = 0;
        for (initial_positions) |pos| cost += std.math.absInt(target - pos) catch unreachable;
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
    var optimal_position = findOptimalAlignmentPosition(&example, &fuel);

    try testing.expectEqual(optimal_position, 2);
    try testing.expectEqual(fuel, 37);
}
