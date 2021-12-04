const std = @import("std");
const testing = std.testing;
const fs = std.fs;
const io = std.io;

pub fn countNumIncreases(inputSeries: []usize) usize {
    // Assert input size

    var prevValue: usize = inputSeries[0];
    var numIncreases: usize = 0;
    for (inputSeries[1..]) |item| {
        if (item > prevValue)
            numIncreases += 1;
        prevValue = item;
    }

    return numIncreases;
}

pub fn run_part1() anyerror!void {
    // Move into main?
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    const filepath = "data/day01_input.txt";
    var f = try fs.cwd().openFile(filepath, fs.File.OpenFlags{ .read = true });
    defer f.close();

    const fileContents = try f.reader().readAllAlloc(allocator, 100e6);

    var seriesCount: usize = 0;
    var it = std.mem.split(fileContents, "\n");
    while (it.next()) |line| {
        seriesCount += 1;
    }
    seriesCount -= 1;
    std.log.info("seriesCount: {d}", .{seriesCount});

    // Convert to integers
    var series: []usize = try allocator.alloc(usize, seriesCount);
    it = std.mem.split(fileContents, "\n");
    var i: usize = 0;
    while (it.next()) |line| {
        if (i < seriesCount) {
            series[i] = try std.fmt.parseInt(usize, line, 10);
            i += 1;
        }
    }

    var numIncreases = countNumIncreases(series[0..]);
    std.log.info("numIncreases: {d}", .{numIncreases});
}

test "test part 1" {
    var testSeries: [4]usize = .{ 10, 11, 10, 11 };
    var result = countNumIncreases(testSeries[0..]);
    try testing.expectEqual(result, 2);
}

test "test empty input" {
    var testSeries: [0]usize = .{};
    var result = countNumIncreases(testSeries[0..]);
    try testing.expectEqual(result, 0);
}
