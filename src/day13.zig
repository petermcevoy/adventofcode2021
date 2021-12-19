const std = @import("std");
const testing = std.testing;
const assert = std.debug.assert;
const log = std.log.scoped(.day12);

const max_points = 1000;
pub fn run() anyerror!void {
    var input_str = @embedFile("../data/day13_input.txt");

    var points_buffer: [max_points]Point = undefined;
    var points = parsePoints(&points_buffer, input_str);
    log.info("Parsed {d} points", .{points.len});

    points = processFolds(points, input_str, 1);
    var count = countPoints(points);
    log.info("Part 1: num points after 1 fold: {d}", .{count});
}

const Point = struct { x: i32, y: i32 };

pub fn parsePoints(points_buffer: *[max_points]Point, str: []const u8) []Point {
    var num_points: usize = 0;
    var it_part = std.mem.split(str, "\n\n");
    var it_points = std.mem.tokenize(it_part.next().?, "\n");
    while (it_points.next()) |line| {
        var it_comp = std.mem.split(line, ",");
        points_buffer[num_points] = Point{
            .x = std.fmt.parseInt(i32, it_comp.next().?, 10) catch unreachable,
            .y = std.fmt.parseInt(i32, it_comp.next().?, 10) catch unreachable,
        };
        num_points += 1;
    }

    return points_buffer[0..num_points];
}

pub fn processFolds(points: []Point, str: []const u8, num_folds_to_process: ?usize) []Point {
    var it_part = std.mem.split(str, "\n\n");
    _ = it_part.next().?; // Skip point declarations

    var it_folds = std.mem.split(it_part.next().?, "\n");
    var folds_processed: usize = 0;
    while (it_folds.next()) |line| {
        var eql_pos = std.mem.indexOf(u8, line, "=").?;
        var axis: u8 = line[eql_pos - 1];
        var value: i32 = std.fmt.parseInt(i32, line[eql_pos + 1 .. line.len], 10) catch unreachable;

        std.debug.print("Folding along {c}={d}\n", .{ axis, value });

        // Mirror points along the fold.
        switch (axis) {
            'x' => {
                for (points) |*p| {
                    if (p.x > value) p.x = value - (p.x - value);
                }
            },
            'y' => {
                for (points) |*p| {
                    if (p.y > value) p.y = value - (p.y - value);
                }
            },
            else => unreachable,
        }
        folds_processed += 1;
        if (num_folds_to_process) |n| {
            if (folds_processed == n) break;
        }
    }

    return points;
}

pub fn countPoints(points: []Point) usize {
    var marks = std.bit_set.ArrayBitSet(u8, max_points * max_points).initEmpty();
    var max_x: i32 = std.math.minInt(i32);
    var max_y: i32 = std.math.minInt(i32);
    var min_x: i32 = std.math.maxInt(i32);
    var min_y: i32 = std.math.maxInt(i32);

    for (points) |p| {
        max_x = std.math.max(max_x, p.x);
        max_y = std.math.max(max_y, p.y);
        min_x = std.math.min(min_x, p.x);
        min_y = std.math.min(min_y, p.y);
    }

    var x_offset: i32 = if (min_x < 0) -1 * min_x else 0;
    var y_offset: i32 = if (min_y < 0) -1 * min_y else 0;

    for (points) |p| {
        var px_offsetted = p.x + x_offset;
        var py_offsetted = p.y + y_offset;
        marks.set(@intCast(usize, py_offsetted) * max_points + @intCast(usize, px_offsetted));
    }

    if (false) { // Print out marks
        var y: i32 = min_y;
        while (y <= max_y) : (y += 1) {
            var py_offsetted = if (min_y < 0) y + (std.math.absInt(min_y) catch unreachable) else y;
            var x: i32 = min_x;
            while (x <= max_x) : (x += 1) {
                var px_offsetted = if (min_x < 0) x + (std.math.absInt(min_x) catch unreachable) else x;
                if (marks.isSet(@intCast(usize, py_offsetted) * max_points + @intCast(usize, px_offsetted))) {
                    std.debug.print("#", .{});
                } else std.debug.print(".", .{});
            }
            std.debug.print("\n", .{});
        }
    }

    var mark_count: usize = marks.count();
    return mark_count;
}

const example =
    \\6,10
    \\0,14
    \\9,10
    \\0,3
    \\10,4
    \\4,11
    \\6,0
    \\6,12
    \\4,1
    \\0,13
    \\10,12
    \\3,4
    \\3,0
    \\8,4
    \\1,10
    \\2,14
    \\8,10
    \\9,0
    \\
    \\fold along y=7
    \\fold along x=5
;

test "part 1" {
    var points_buffer: [max_points]Point = undefined;
    var points = parsePoints(&points_buffer, example);
    points = processFolds(points, example, 1);
    var count = countPoints(points);
    try testing.expectEqual(count, 17);
}
