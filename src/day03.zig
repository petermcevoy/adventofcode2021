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
    log.info("\tgammaRate: {d}\t(0b{b:12})", .{ gamma, gamma });
    log.info("\tepsilonRate: {d}\t(0b{b:12})", .{ epsilon, epsilon });
    log.info("\tgammaRate*epsilonRate: {d}", .{@as(u32, epsilon) * @as(u32, gamma)});
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
