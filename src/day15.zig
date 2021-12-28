const std = @import("std");
const testing = std.testing;
const log = std.log.scoped(.day15);

pub fn run() anyerror!void {
    var input_str = @embedFile("../data/day15_input.txt");

    const map_size = 100;
    var map: [map_size * map_size]u32 = undefined;
    populateMapFromStr(&map, input_str);

    var optimal_path_risk: u32 = findLowestRiskPath(map_size, &map);
    log.info("Part 1: {d}", .{optimal_path_risk});
}

pub fn populateMapFromStr(map: []u32, str: []const u8) void {
    var it_row = std.mem.tokenize(u8, str, "\n");
    var i_row: usize = 0;
    while (it_row.next()) |row| : (i_row += 1) {
        for (row) |c, i_c| {
            map[row.len * i_row + i_c] = std.fmt.parseInt(u32, &.{c}, 10) catch unreachable;
        }
    }
}

pub fn findLowestRiskPath(comptime map_size: u32, risk_map: *[map_size * map_size]u32) u32 {
    var visited_map = [_]bool{false} ** (map_size * map_size);
    var distance_map = [_]u32{std.math.maxInt(u32)} ** (map_size * map_size);

    var start_pos = [2]usize{ 0, 0 };
    var end_pos = [2]usize{ map_size - 1, map_size - 1 };

    var current_pos = start_pos;
    distance_map[0] = 0;
    var unvisted_count: usize = map_size * map_size;

    const search_directions: [4][2]i32 = .{
        .{ 1, 0 },
        .{ -1, 0 },
        .{ 0, 1 },
        .{ 0, -1 },
    };

    while (unvisted_count > 0) {
        // Visit neighbours of current_pos
        var current_pos_index: usize = current_pos[1] * map_size + current_pos[0];

        // Check if we've reached the end! Return the total distance (risk).
        if (std.mem.eql(usize, &current_pos, &end_pos)) return distance_map[current_pos_index];

        for (search_directions) |search_dir| {
            if (current_pos[0] == 0 and search_dir[0] == -1) continue;
            if (current_pos[0] == (map_size - 1) and search_dir[0] == 1) continue;
            if (current_pos[1] == 0 and search_dir[1] == -1) continue;
            if (current_pos[1] == (map_size - 1) and search_dir[1] == 1) continue;

            var new_pos = [2]usize{ @intCast(usize, @intCast(i32, current_pos[0]) + search_dir[0]), @intCast(usize, @intCast(i32, current_pos[1]) + search_dir[1]) };
            var new_pos_index = new_pos[1] * map_size + new_pos[0];
            if (!visited_map[new_pos_index]) {
                var current_distance = distance_map[current_pos_index];
                var new_distance_to_neighbour = current_distance + risk_map[new_pos_index];
                var prev_marked_distance_to_neighbour = distance_map[new_pos_index];
                if (new_distance_to_neighbour < prev_marked_distance_to_neighbour) {
                    distance_map[new_pos_index] = new_distance_to_neighbour;
                }
            }
        }

        // Current node is now considered visited.
        visited_map[current_pos_index] = true;
        unvisted_count -= 1;

        // Set the visited neighbour with the smallest tentative distance as the new current_node.
        var shortest_tentative_distance_pos: ?[2]usize = null;
        var shortest_tentative_distance: u32 = std.math.maxInt(u32);
        for (distance_map) |distance, i| {
            if (visited_map[i]) continue;
            if (distance < shortest_tentative_distance) {
                shortest_tentative_distance = distance;
                shortest_tentative_distance_pos = .{ i % map_size, @divTrunc(i, map_size) };
                //std.debug.print("i: {d}, visited_map[i]: {d}, @divTrunc(i, map_size): {d}, i % map_size: {d}\n", .{ i, visited_map[i], @divTrunc(i, map_size), i % map_size });
                //std.debug.print("shortest_distance_pos: {d}\n", .{shortest_tentative_distance_pos});
            }
        }

        current_pos = shortest_tentative_distance_pos.?;
    }

    unreachable;
}

const example =
    \\1163751742
    \\1381373672
    \\2136511328
    \\3694931569
    \\7463417111
    \\1319128137
    \\1359912421
    \\3125421639
    \\1293138521
    \\2311944581
;

test "part 1" {
    const map_size = 10;
    var map: [map_size * map_size]u32 = undefined;
    populateMapFromStr(&map, example);

    var optimal_path_risk: u32 = findLowestRiskPath(map_size, &map);
    try testing.expectEqual(optimal_path_risk, 40);
}
