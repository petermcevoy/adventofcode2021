const std = @import("std");
const testing = std.testing;
const assert = std.debug.assert;
const log = std.log.scoped(.day09);

pub fn run() anyerror!void {
    var input_str = @embedFile("../data/day09_input.txt");
    var map = HeightMap(100, 100).fromStr(input_str);
    var risk_level = calcLowPointRiskLevels(&map);
    log.info("Part 1: {d}", .{risk_level});
}

pub fn HeightMap(comptime width: usize, comptime height: usize) type {
    return struct {
        map_width: usize = width,
        map_height: usize = height,
        height_values: [width * height]u8,

        const Self = @This();

        pub fn fromStr(str: []const u8) Self {
            var map = Self{
                .height_values = [_]u8{0} ** (width * height),
            };
            var line_it = std.mem.tokenize(str, "\n");
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

        pub fn isLowPoint(self: *const Self, x: i32, y: i32) bool {
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
                    return false;
                }
            }

            // Did not find a adjascent lower point, this is a low point.
            return true;
        }
    };
}

pub fn calcLowPointRiskLevels(map: anytype) u32 {
    var sum_risk_level: u32 = 0;

    var y: i32 = 0;
    while (y < map.map_height) : (y += 1) {
        var x: i32 = 0;
        while (x < map.map_width) : (x += 1) {
            if (map.isLowPoint(x, y)) {
                var val = map.getHeight(x, y).?;
                sum_risk_level += val + 1;
            }
        }
    }

    return sum_risk_level;
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
    var risk_level = calcLowPointRiskLevels(&map);
    try testing.expectEqual(risk_level, 15);
}
