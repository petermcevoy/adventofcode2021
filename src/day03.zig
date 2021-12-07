const std = @import("std");
const testing = std.testing;
const assert = std.debug.assert;

const log = std.log.scoped(.day03);

pub fn run(allocator: *std.mem.Allocator) anyerror!void {
    var inputStr = @embedFile("../data/day03_input.txt");
    var data = try parseInputStr(u12, allocator, inputStr);
    defer allocator.free(data);

    var gamma: u12 = 0;
    var epsilon: u12 = 0;
    parseGammaAndEpsilonRate(u12, data, &gamma, &epsilon);

    log.info("Part1:", .{});
    log.info("\tgammaRate: {d}\t(0b{b:0>12})", .{ gamma, gamma });
    log.info("\tepsilonRate: {d}\t(0b{b:0>12})", .{ epsilon, epsilon });
    log.info("\tgammaRate*epsilonRate: {d}", .{@as(u32, epsilon) * @as(u32, gamma)});

    var oxygenRating: u12 = 0;
    var co2ScrubberRating: u12 = 0;
    try parseRating(u12, testing.allocator, data, &oxygenRating, true);
    try parseRating(u12, testing.allocator, data, &co2ScrubberRating, false);

    log.info("Part2:", .{});
    log.info("\tO2 Rating: {d}\t(0b{b:0>12})", .{ oxygenRating, oxygenRating });
    log.info("\tCO2 Rating: {d}\t(0b{b:0>12})", .{ co2ScrubberRating, co2ScrubberRating });
    log.info("\to2*co2: {d}", .{@as(u32, oxygenRating) * @as(u32, co2ScrubberRating)});
}

pub fn parseInputStr(comptime T: type, allocator: *std.mem.Allocator, inputStr: []const u8) ![]T {
    var parsedData = std.ArrayList(T).init(allocator);
    var it = std.mem.split(inputStr, "\n");
    while (it.next()) |line| {
        if (line.len == 0) continue;
        var value: T = std.fmt.parseInt(T, line, 2) catch |err| {
            log.err("Error when parsing line: {s}", .{line});
            return err;
        };
        try parsedData.append(try std.fmt.parseInt(T, line, 2));
    }
    return parsedData.toOwnedSlice();
}

pub fn parseGammaAndEpsilonRate(comptime T: type, data: []const T, outGamma: *T, outEpsilon: *T) void {
    comptime assert(T == u5 or T == u12);

    // Sum columns.
    const numBits = @bitSizeOf(T);
    var colsum: [numBits]u32 = .{0} ** numBits;
    var numRows: usize = 0;
    for (data) |row| {
        // comptime unroll?
        var mask: T = 1;
        var j: usize = 1;
        while (j <= numBits) : (j += 1) {
            colsum[numBits - j] += @boolToInt(row & mask > 0);
            mask = mask << 1;
        }
        numRows += 1;
    }

    // Check the most common for each column
    var gamma: T = 0;
    var epsilon: T = 0;

    var mask: T = 1;
    var j: usize = 1;
    while (j <= numBits) : (j += 1) {
        if (colsum[numBits - j] > numRows / 2) {
            gamma |= mask;
        }
        mask = mask << 1;
    }
    epsilon = ~gamma;

    outGamma.* = gamma;
    outEpsilon.* = epsilon;
}

// Not very happy with this one....
pub fn parseRating(comptime T: type, allocator: *std.mem.Allocator, data: []const T, outRating: *T, useMostCommonBit: bool) !void {
    comptime assert(T == u5 or T == u12);

    var filterList: []bool = try allocator.alloc(bool, data.len);
    defer allocator.free(filterList);
    std.mem.set(bool, filterList, true);

    var numCandidates: usize = data.len;

    const numCols = @bitSizeOf(T);
    var iCol: usize = 0;
    while (iCol < numCols) : (iCol += 1) {
        var mask: T = @bitReverse(T, @as(T, 1) << @intCast(u4, iCol));
        var iRow: usize = 0;

        var colSum: usize = 0;
        var colCount: usize = 0;
        for (data) |row, i| {
            if (filterList[i]) {
                colSum += @boolToInt(row & mask > 0);
                colCount += 1;
            }
        }
        var mostCommonBitForCol: bool = colSum > colCount / 2 or colCount == 2;
        var checkAgainst: u1 = undefined;
        if (useMostCommonBit) {
            checkAgainst = @boolToInt(mostCommonBitForCol);
        } else {
            checkAgainst = @boolToInt(!mostCommonBitForCol);
        }

        while (iRow < data.len) : (iRow += 1) {
            if (filterList[iRow]) {
                if (@boolToInt(data[iRow] & mask > 0) != checkAgainst) {
                    filterList[iRow] = false;
                    numCandidates -= 1;
                }
            }
        }

        if (numCandidates == 1)
            break;
    }
    assert(numCandidates == 1);

    for (filterList) |active, i| {
        if (active) {
            outRating.* = data[i];
            break;
        }
    }
}

test "test part 1" {
    const example_input =
        \\00100
        \\11110
        \\10110
        \\10111
        \\10101
        \\01111
        \\00111
        \\11100
        \\10000
        \\11001
        \\00010
        \\01010
    ;

    var data = try parseInputStr(u5, testing.allocator, example_input);
    defer testing.allocator.free(data);

    var gamma: u5 = 0;
    var epsilon: u5 = 0;
    parseGammaAndEpsilonRate(u5, data, &gamma, &epsilon);

    try testing.expectEqual(gamma, 0b10110);
    try testing.expectEqual(epsilon, 0b01001);
}

test "test part 2" {
    const example_input =
        \\00100
        \\11110
        \\10110
        \\10111
        \\10101
        \\01111
        \\00111
        \\11100
        \\10000
        \\11001
        \\00010
        \\01010
    ;

    var data = try parseInputStr(u5, testing.allocator, example_input);
    defer testing.allocator.free(data);

    var oxygenRating: u5 = 0;
    var co2ScrubberRating: u5 = 0;
    try parseRating(u5, testing.allocator, data, &oxygenRating, true);
    try parseRating(u5, testing.allocator, data, &co2ScrubberRating, false);

    try testing.expectEqual(oxygenRating, 0b10111);
    try testing.expectEqual(co2ScrubberRating, 0b01010);
}
