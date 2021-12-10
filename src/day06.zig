const std = @import("std");
const testing = std.testing;
const assert = std.debug.assert;

const log = std.log.scoped(.day06);

pub fn run(allocator: *std.mem.Allocator) anyerror!void {
    var inputStr = @embedFile("../data/day06_input.txt");
    var initialState = try parseInputStrAlloc(allocator, inputStr);
    defer allocator.free(initialState);

    var result = try simulateNumFish(allocator, initialState, 80);

    log.info("Part 1: Number of lanternfish after 80 days: {d}", .{result});
}

pub fn simulateNumFish(allocator: *std.mem.Allocator, initialState: []u8, numDays: usize) !usize {
    var stateList = std.ArrayList(u8).init(allocator);
    defer stateList.deinit();
    try stateList.appendSlice(initialState);

    var iDay: usize = 0;
    while (iDay < numDays) : (iDay += 1) {
        var numNewFishToCreate: usize = 0;
        for (stateList.items) |counter, i| {
            if (counter == 0) {
                stateList.items[i] = 6;
                numNewFishToCreate += 1;
            } else {
                stateList.items[i] -= 1;
            }
        }

        // Extend our states vector and create new fish.
        // New fish have counter set to 8.
        try stateList.appendNTimes(8, numNewFishToCreate);
    }

    return stateList.items.len;
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
    try testing.expectEqual(try simulateNumFish(testing.allocator, initialState, 18), 26);
    try testing.expectEqual(try simulateNumFish(testing.allocator, initialState, 80), 5934);
}
