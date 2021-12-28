const std = @import("std");
const testing = std.testing;
const assert = std.debug.assert;
const max = std.math.max;
const min = std.math.min;

const log = std.log.scoped(.day05);

pub fn run(allocator: std.mem.Allocator) anyerror!void {
    var inputStr = @embedFile("../data/day05_input.txt");
    var reader = std.io.fixedBufferStream(inputStr).reader();

    var lineSegmentsList = std.ArrayList(LineSegment).init(allocator);
    defer lineSegmentsList.deinit();
    while (try parseLineSegment(reader)) |lineSegment| {
        try lineSegmentsList.append(lineSegment);
    }

    {
        var occupancyMap = try generateOccupancyMapAlloc(allocator, lineSegmentsList.items, false);
        defer allocator.free(occupancyMap);
        var num2Overlaps: usize = 0;
        for (occupancyMap) |v| {
            if (v >= 2) num2Overlaps += 1;
        }
        log.info("Part 1: Number of points with overlaps >= 2: {d}", .{num2Overlaps});
    }

    {
        var occupancyMap = try generateOccupancyMapAlloc(allocator, lineSegmentsList.items, true);
        defer allocator.free(occupancyMap);
        var num2Overlaps: usize = 0;
        for (occupancyMap) |v| {
            if (v >= 2) num2Overlaps += 1;
        }
        log.info("Part 2: Number of points with overlaps >= 2: {d}", .{num2Overlaps});
    }
}

const LineSegment = struct {
    x0: u32,
    y0: u32,
    x1: u32,
    y1: u32,
};

pub fn parseLineSegment(reader: anytype) !?LineSegment {
    var buffer: [1024]u8 = undefined;
    var line = (try reader.readUntilDelimiterOrEof(&buffer, '\n')) orelse return null;

    var it = std.mem.tokenize(u8, line, " -> ");
    var fromStr = it.next().?;
    var toStr = it.next().?;

    var itFrom = std.mem.split(u8, fromStr, ",");
    var itTo = std.mem.split(u8, toStr, ",");

    var lineSegment = LineSegment{
        .x0 = try std.fmt.parseInt(u32, itFrom.next().?, 10),
        .y0 = try std.fmt.parseInt(u32, itFrom.next().?, 10),
        .x1 = try std.fmt.parseInt(u32, itTo.next().?, 10),
        .y1 = try std.fmt.parseInt(u32, itTo.next().?, 10),
    };

    return lineSegment;
}

const mapWidth = 1000;
const mapHeight = 1000;

pub fn generateOccupancyMapAlloc(allocator: std.mem.Allocator, lineSegments: []LineSegment, comptime considerDiagonals: bool) ![]u8 {
    var occupancyMap: []u8 = try allocator.alloc(u8, mapWidth * mapHeight);
    std.mem.set(u8, occupancyMap, 0);

    // Fill the map
    for (lineSegments) |lineSegment| {
        var x0 = @intCast(i32, lineSegment.x0);
        var x1 = @intCast(i32, lineSegment.x1);
        var y0 = @intCast(i32, lineSegment.y0);
        var y1 = @intCast(i32, lineSegment.y1);

        var dx: i32 = if (x0 < x1) 1 else -1;
        var dy: i32 = if (y0 < y1) 1 else -1;
        if (x0 == x1)
            dx = 0;
        if (y0 == y1)
            dy = 0;

        var isAxisAligned = (x0 == x1 or y0 == y1);
        if (!considerDiagonals and !isAxisAligned) continue;

        var lineLen = max(std.math.absCast(x0 - x1), std.math.absCast(y0 - y1));

        var x = x0;
        var y = y0;
        var j: usize = 0;
        while (j <= lineLen) : (j += 1) {
            occupancyMap[@intCast(usize, y) * mapWidth + @intCast(usize, x)] += 1;
            x += dx;
            y += dy;
        }
    }

    return occupancyMap;
}

pub fn printOccupancyMap(map: []u8) void {
    var y: usize = 0;
    const y1: usize = 10;
    while (y <= y1) : (y += 1) {
        var x: usize = 0;
        const x1: usize = 10;
        while (x <= x1) : (x += 1) {
            var val = map[y * mapWidth + x];
            if (val > 0) {
                std.debug.print("{d} ", .{map[y * mapWidth + x]});
            } else {
                std.debug.print(". ", .{});
            }
        }
        std.debug.print("\n", .{});
    }
}

test "test parse line segment" {
    const example = "0,9 -> 5,9";
    var reader = std.io.fixedBufferStream(example).reader();

    var lineSegment = (try parseLineSegment(reader)).?;

    try testing.expectEqual(lineSegment.x0, 0);
    try testing.expectEqual(lineSegment.y0, 9);
    try testing.expectEqual(lineSegment.x1, 5);
    try testing.expectEqual(lineSegment.y1, 9);
}

test "part 1" {
    const example =
        \\0,9 -> 5,9
        \\8,0 -> 0,8
        \\9,4 -> 3,4
        \\2,2 -> 2,1
        \\7,0 -> 7,4
        \\6,4 -> 2,0
        \\0,9 -> 2,9
        \\3,4 -> 1,4
        \\0,0 -> 8,8
        \\5,5 -> 8,2
    ;

    var reader = std.io.fixedBufferStream(example).reader();

    var lineSegmentsList = std.ArrayList(LineSegment).init(testing.allocator);
    defer lineSegmentsList.deinit();
    while (try parseLineSegment(reader)) |lineSegment| {
        try lineSegmentsList.append(lineSegment);
    }

    {
        var occupancyMap = try generateOccupancyMapAlloc(testing.allocator, lineSegmentsList.items, false);
        defer testing.allocator.free(occupancyMap);

        var num2Overlaps: usize = 0;
        for (occupancyMap) |v| {
            if (v >= 2) num2Overlaps += 1;
        }
        try testing.expectEqual(num2Overlaps, 5);
    }

    {
        var occupancyMap = try generateOccupancyMapAlloc(testing.allocator, lineSegmentsList.items, true);
        defer testing.allocator.free(occupancyMap);

        var num2Overlaps: usize = 0;
        for (occupancyMap) |v| {
            if (v >= 2) num2Overlaps += 1;
        }
        try testing.expectEqual(num2Overlaps, 12);
    }
}
