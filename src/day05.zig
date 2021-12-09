const std = @import("std");
const testing = std.testing;
const assert = std.debug.assert;
const max = std.math.max;
const min = std.math.min;

const log = std.log.scoped(.day05);

pub fn run(allocator: *std.mem.Allocator) anyerror!void {
    var inputStr = @embedFile("../data/day05_input.txt");
    var reader = std.io.fixedBufferStream(inputStr).reader();

    var lineSegmentsList = std.ArrayList(LineSegment).init(allocator);
    defer lineSegmentsList.deinit();
    while (try parseLineSegment(reader)) |lineSegment| {
        try lineSegmentsList.append(lineSegment);
    }

    var occupancyMap = try generateOccupancyMapAlloc(allocator, lineSegmentsList.items);
    defer allocator.free(occupancyMap);

    var num2Overlaps: usize = 0;
    for (occupancyMap) |v| {
        if (v >= 2) num2Overlaps += 1;
    }

    log.info("Part 1: Number of points with overlaps >= 2: {d}.", .{num2Overlaps});
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

    var it = std.mem.tokenize(line, " -> ");
    var fromStr = it.next().?;
    var toStr = it.next().?;

    var itFrom = std.mem.split(fromStr, ",");
    var itTo = std.mem.split(toStr, ",");

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

pub fn generateOccupancyMapAlloc(allocator: *std.mem.Allocator, lineSegments: []LineSegment) ![]u8 {
    var occupancyMap: []u8 = try allocator.alloc(u8, mapWidth * mapHeight);
    std.mem.set(u8, occupancyMap, 0);

    // Fill the map
    line: for (lineSegments) |lineSegment, i| {
        var y = min(lineSegment.y0, lineSegment.y1);
        var y1 = max(lineSegment.y0, lineSegment.y1);

        while (y <= y1) : (y += 1) {
            var x = min(lineSegment.x0, lineSegment.x1);
            var x1 = max(lineSegment.x0, lineSegment.x1);

            // Only consider lines that are horizontal or vertical...
            if (!(x == x1 or y == y1)) continue :line;

            while (x <= x1) : (x += 1) {
                occupancyMap[y * mapWidth + x] += 1;
            }
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

    var occupancyMap = try generateOccupancyMapAlloc(testing.allocator, lineSegmentsList.items);
    defer testing.allocator.free(occupancyMap);

    var num2Overlaps: usize = 0;
    for (occupancyMap) |v| {
        if (v >= 2) num2Overlaps += 1;
    }
    try testing.expectEqual(num2Overlaps, 5);
}
