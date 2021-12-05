const std = @import("std");
const testing = std.testing;
const fs = std.fs;
const io = std.io;
const assert = std.debug.assert;

const log = std.log.scoped(.day01);

pub fn run() anyerror!void {
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
    log.info("Part 1:\tnumIncreases: {d}", .{numIncreases});

    const windowSize = 3;
    var numIncreasesWindowed = countNumIncreasesWindowed(series[0..], windowSize);
    log.info("Part 2:\tnumIncreasesWindowed: {d}", .{numIncreasesWindowed});
}

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

fn countNumIncreasesWindowed(inputSeries: []usize, comptime windowSize: usize) usize {
    assert(inputSeries.len > windowSize);

    var numIncreases: usize = 0;
    var currentWindow: [windowSize]usize = inputSeries[0..windowSize].*;

    var prevWindowSum: usize = 0;
    for (currentWindow) |value| {
        prevWindowSum += value;
    }

    for (inputSeries[windowSize..]) |value, i| {
        // Move all values back one and add the new value.
        var j: usize = 0;
        while (j < windowSize - 1) : (j += 1) {
            currentWindow[j] = currentWindow[j + 1];
        }
        currentWindow[windowSize - 1] = value;

        var currentWindowSum: usize = 0;
        for (currentWindow) |sumValue| {
            currentWindowSum += sumValue;
        }

        if (currentWindowSum > prevWindowSum) {
            numIncreases += 1;
        }
        prevWindowSum = currentWindowSum;
    }
    return numIncreases;
}

test "test part 1" {
    var testSeries = [_]usize{
        199,
        200,
        208,
        210,
        200,
        207,
        240,
        269,
        260,
        263,
    };
    var result = countNumIncreases(testSeries[0..]);
    try testing.expectEqual(result, 7);
}

test "test part 2" {
    var testSeries: [10]usize = .{ 199, 200, 208, 210, 200, 207, 240, 269, 260, 263 };
    var result = countNumIncreasesWindowed(testSeries[0..], 3);
    try testing.expectEqual(result, 5);
}
