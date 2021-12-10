const std = @import("std");
const testing = std.testing;
const assert = std.debug.assert;

const log = std.log.scoped(.day06);

pub fn run(allocator: *std.mem.Allocator) anyerror!void {
    var inputStr = @embedFile("../data/day06_input.txt");
    var initialState = try parseInputStrAlloc(allocator, inputStr);
    defer allocator.free(initialState);

    log.info("Part 1: Number of lanternfish after 80 days: {d}", .{try simulateNumFish(initialState, 80)});
    log.info("Part 2: Number of lanternfish after 256 days: {d}", .{try simulateNumFish(initialState, 256)});
}

pub fn simulateNumFish(initialState: []u8, numDays: usize) !usize {

    // There are 9 states 0,1,2,...,8
    var states = [_]usize{0} ** 9;
    for (states) |state, i| {
        for (initialState) |fishState| {
            states[i] += @boolToInt(fishState == i);
        }
    }

    var iDay: usize = 0;
    while (iDay < numDays) : (iDay += 1) {
        // Simulate the days for each group
        var numResetFish: usize = 0;

        // Age all fish
        var iState: usize = 0;
        while (iState <= 8) : (iState += 1) {
            if (iState == 0) {
                // These fish are moved to 6
                numResetFish = states[0];
                states[0] = 0;
            } else {
                states[iState - 1] = states[iState];
                states[iState] = 0;
            }
        }

        // Add the reset fish to group 6 and create new fish in group 8
        states[6] += numResetFish;
        states[8] += numResetFish;
    }

    var numFish: usize = 0;
    for (states) |state| numFish += state;

    return numFish;
}

pub fn parseInputStrAlloc(allocator: *std.mem.Allocator, str: []const u8) ![]u8 {
    var stateList = std.ArrayList(u8).init(allocator);
    errdefer stateList.deinit();

    var strWithoutEof = str;
    if (str[str.len - 1] == 10) strWithoutEof = str[0..(str.len - 1)];

    var it = std.mem.split(strWithoutEof, ",");
    while (it.next()) |v| {
        try stateList.append(try std.fmt.parseInt(u8, v, 10));
    }

    return stateList.toOwnedSlice();
}

test "part 1" {
    const example = "3,4,3,1,2";
    var initialState = try parseInputStrAlloc(testing.allocator, example);
    defer testing.allocator.free(initialState);

    // In this example, after 18 days, there are a total of 26 fish. After 80 days, there would be a total of 5934.
    try testing.expectEqual(try simulateNumFish(initialState, 18), 26);
    try testing.expectEqual(try simulateNumFish(initialState, 80), 5934);
}

test "part 2" {
    const example = "3,4,3,1,2";
    var initialState = try parseInputStrAlloc(testing.allocator, example);
    defer testing.allocator.free(initialState);

    try testing.expectEqual(try simulateNumFish(initialState, 256), 26984457539);
}
