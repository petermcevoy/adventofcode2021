const std = @import("std");
const testing = std.testing;
const stdout = std.io.getStdOut().writer();

pub fn run(allocator: std.mem.Allocator) anyerror!void {
    var input_str = @embedFile("../data/day15_input.txt");

    var map = Map(100).fromStr(input_str);
    var optimal_path_risk_part1: u32 = findLowestRiskPath(100, allocator, &map);
    try stdout.print("Part 1: {d}\n", .{optimal_path_risk_part1});

    var optimal_path_risk_part2: u32 = findLowestRiskPath(100 * 5, allocator, &map);
    try stdout.print("Part 2: {d}\n", .{optimal_path_risk_part2});
}

pub fn Map(comptime template_size: usize) type {
    return struct {
        template: [template_size * template_size]u32,
        template_size: usize = template_size,

        pub fn fromStr(str: []const u8) @This() {
            var it_row = std.mem.tokenize(u8, str, "\n");

            var map: @This() = .{
                .template = undefined,
            };

            var i_row: usize = 0;
            while (i_row < template_size) : (i_row += 1) {
                var row = it_row.next().?;
                var i_col: usize = 0;
                while (i_col < template_size) : (i_col += 1) {
                    map.template[template_size * i_row + i_col] = std.fmt.parseInt(u32, &.{row[i_col]}, 10) catch unreachable;
                }
            }

            return map;
        }

        pub fn getRisk(self: *@This(), x: usize, y: usize) u32 {
            var tile_x: usize = @divTrunc(x, template_size);
            var tile_y: usize = @divTrunc(y, template_size);
            var wrapped_x: usize = x % template_size;
            var wrapped_y: usize = y % template_size;
            var val: u32 = self.template[wrapped_y * template_size + wrapped_x];
            return ((val + @intCast(u32, tile_x) + @intCast(u32, tile_y) - 1) % 9) + 1;
        }
    };
}

fn compareFn(context: []u32, a: usize, b: usize) std.math.Order {
    return std.math.order(context[a], context[b]);
}

pub fn findLowestRiskPath(comptime map_size: usize, allocator: std.mem.Allocator, map: anytype) u32 {
    var visited_map = [_]bool{false} ** (map_size * map_size);
    var distance_map = [_]u32{std.math.maxInt(u32)} ** (map_size * map_size);

    distance_map[0] = 0; // Start position has distance 0.
    var end_pos = [2]usize{ map_size - 1, map_size - 1 };

    var unvisited = std.PriorityQueue(usize, []u32, compareFn)
        .init(allocator, &distance_map);
    defer unvisited.deinit();
    unvisited.ensureTotalCapacity(map_size * map_size) catch unreachable;
    unvisited.add(0) catch unreachable;

    const search_directions: [4][2]i32 = .{
        .{ 1, 0 },
        .{ -1, 0 },
        .{ 0, 1 },
        .{ 0, -1 },
    };

    while (unvisited.count() > 0) {
        // New current pos is the one with the lowest distance
        var current_pos_index: usize = unvisited.remove();
        if (visited_map[current_pos_index]) continue;
        var current_pos = [2]usize{ current_pos_index % map_size, @divTrunc(current_pos_index, map_size) };

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
                var new_distance_to_neighbour = current_distance + map.getRisk(new_pos[0], new_pos[1]);
                var prev_marked_distance_to_neighbour = distance_map[new_pos_index];
                if (new_distance_to_neighbour < prev_marked_distance_to_neighbour) {
                    distance_map[new_pos_index] = new_distance_to_neighbour;

                    unvisited.add(new_pos_index) catch unreachable;
                }
            }
        }

        // Current node is now considered visited.
        visited_map[current_pos_index] = true;
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
    var map = Map(10).fromStr(example);
    var optimal_path_risk: u32 = findLowestRiskPath(10, std.testing.allocator, &map);
    try testing.expectEqual(optimal_path_risk, 40);
}

test "part 2" {
    var map = Map(10).fromStr(example);
    var optimal_path_risk: u32 = findLowestRiskPath(10 * 5, std.testing.allocator, &map);
    try testing.expectEqual(optimal_path_risk, 315);
}
