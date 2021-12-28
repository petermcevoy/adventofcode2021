const std = @import("std");
const testing = std.testing;
const assert = std.debug.assert;
const log = std.log.scoped(.day09);

pub fn run() anyerror!void {
    var input_str = @embedFile("../data/day09_input.txt");
    var map = HeightMap(100, 100).fromStr(input_str);

    var top3_basin_sizes = [_]u32{0} ** 3;
    var sum_risk_level: u32 = 0;
    processMap(&map, &sum_risk_level, &top3_basin_sizes);

    log.info("Part 1: {d}", .{sum_risk_level});
    log.info("Part 2: {d}: {d}", .{ top3_basin_sizes, top3_basin_sizes[0] * top3_basin_sizes[1] * top3_basin_sizes[2] });
}

pub fn processMap(map: anytype, out_sum_risk_level: ?*u32, out_top3_basin_sizes: ?*[3]u32) void {
    var top3_basin_sizes = [_]?u32{null} ** 3;
    var sum_risk_level: u32 = 0;

    var y: i32 = 0;
    while (y < map.map_height) : (y += 1) {
        var x: i32 = 0;
        while (x < map.map_width) : (x += 1) {
            if (map.getLowPoint(x, y)) |h| {
                sum_risk_level += h + 1;
                var basin_size = findBasinSizeFromPoint(map, x, y);
                for (top3_basin_sizes) |_, i| {
                    if (top3_basin_sizes[i] == null or basin_size > top3_basin_sizes[i].?) {
                        if (i == 0) top3_basin_sizes[1] = top3_basin_sizes[0];
                        if (i == 0 or i == 1) top3_basin_sizes[2] = top3_basin_sizes[1];
                        top3_basin_sizes[i] = basin_size;
                        break;
                    }
                }
            }
        }
    }

    if (out_sum_risk_level != null) out_sum_risk_level.?.* = sum_risk_level;
    if (out_top3_basin_sizes != null) {
        for (out_top3_basin_sizes.?) |*entry, i| entry.* = top3_basin_sizes[i].?;
    }
}

pub fn HeightMap(comptime width: usize, comptime height: usize) type {
    return struct {
        map_width: usize = width,
        map_height: usize = height,
        height_values: [width * height]u8,
        basin_marks: [width * height]bool = [_]bool{false} ** (width * height),

        const Self = @This();

        pub fn fromStr(str: []const u8) Self {
            var map = Self{
                .height_values = [_]u8{0} ** (width * height),
            };
            var line_it = std.mem.tokenize(u8, str, "\n");
            var y: usize = 0;
            while (line_it.next()) |line| {
                assert(y < height);
                for (line) |c, x| {
                    assert(x < width);
                    map.height_values[y * width + x] = std.fmt.parseInt(u8, &[1]u8{c}, 10) catch unreachable;
                }
                y += 1;
            }
            return map;
        }

        pub fn getHeight(self: *const Self, x: i32, y: i32) ?u8 {
            if (x < 0 or y < 0) return null;
            if (x >= width or y >= height) return null;
            return self.height_values[@intCast(usize, y) * width + @intCast(usize, x)];
        }

        pub fn getLowPoint(self: *const Self, x: i32, y: i32) ?u32 {
            var cmp_val = self.getHeight(x, y).?;

            var points_to_check: [4][2]i32 = undefined;
            points_to_check[0] = [2]i32{ x, y - 1 };
            points_to_check[1] = [2]i32{ x, y + 1 };
            points_to_check[2] = [2]i32{ x - 1, y };
            points_to_check[3] = [2]i32{ x + 1, y };

            for (points_to_check) |pt| {
                var val = self.getHeight(pt[0], pt[1]);
                if (val == null) continue;

                if (val.? <= cmp_val) {
                    return null;
                }
            }

            // Did not find a adjascent lower point, this is a low point.
            return cmp_val;
        }

        pub fn setBasin(self: *Self, x: i32, y: i32) bool {
            var ux = @intCast(usize, x);
            var uy = @intCast(usize, y);
            var was_already_set = self.basin_marks[uy * width + ux];
            if (was_already_set) return false;

            self.basin_marks[uy * width + ux] = true;
            return true;
        }
    };
}

pub fn findBasinSizeFromPoint(map: anytype, x: i32, y: i32) u32 {
    // grow from this starting position up until reaching height 9.
    const directions: [4][2]i32 = .{
        [2]i32{ 0, 1 },
        [2]i32{ 0, -1 },
        [2]i32{ 1, 0 },
        [2]i32{ -1, 0 },
    };

    var num_points_marked_as_basin: u32 = 0;

    // Include self
    if (map.setBasin(x, y))
        num_points_marked_as_basin += 1;

    var start_height = map.getHeight(x, y).?;

    for (directions) |dir| {
        var prev_val = start_height;
        var curr_x: i32 = x + dir[0];
        var curr_y: i32 = y + dir[1];
        var val = map.getHeight(curr_x, curr_y);

        while (val != null and val.? > prev_val and val.? < 9) {
            if (map.setBasin(curr_x, curr_y)) {
                num_points_marked_as_basin += 1;

                // Explore basin from this point
                num_points_marked_as_basin += findBasinSizeFromPoint(map, curr_x, curr_y);
            }

            curr_x += dir[0];
            curr_y += dir[1];
            val = map.getHeight(curr_x, curr_y);
        }
    }

    return num_points_marked_as_basin;
}

const example =
    \\2199943210
    \\3987894921
    \\9856789892
    \\8767896789
    \\9899965678
;

test "part 1" {
    var map = HeightMap(10, 5).fromStr(example);
    var sum_risk_level: u32 = 0;
    processMap(&map, &sum_risk_level, null);
    try testing.expectEqual(sum_risk_level, 15);
}

test "part 2" {
    // Find three largest basins
    var map = HeightMap(10, 5).fromStr(example);
    var top3_basin_sizes = [_]u32{0} ** 3;
    processMap(&map, null, &top3_basin_sizes);
    try testing.expectEqual(top3_basin_sizes, [3]u32{ 14, 9, 9 });
}
