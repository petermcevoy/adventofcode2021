const std = @import("std");
const testing = std.testing;
const assert = std.debug.assert;
const log = std.log.scoped(.day11);

pub fn run() anyerror!void {
    var input_str = @embedFile("../data/day11_input.txt");
    var states = OctopusStates.fromStr(input_str);

    var sum_num_flashes: usize = 0;
    var i: usize = 0;
    var i_sync: ?usize = null;
    while (i < 100 or i_sync == null) : (i += 1) {
        var num_flashes = states.simulateStep();

        if (i < 100) sum_num_flashes += num_flashes;
        if (i_sync == null and num_flashes == 10 * 10) {
            i_sync = i;
        }
    }
    log.info("Part 1: num flashes {d}", .{sum_num_flashes});
    log.info("Part 2: steps for first sync {d}", .{i_sync.? + 1});
}

const width = 10;
const height = 10;
const OctopusStates = struct {
    values: [width * height]u8 = [_]u8{0} ** (width * height), // energy levels
    has_flashed: [width * height]bool = [_]bool{false} ** (width * height),

    const Self = @This();

    pub fn fromStr(str: []const u8) Self {
        var map: Self = undefined;
        var line_it = std.mem.tokenize(u8, str, "\n");
        var y: usize = 0;
        while (line_it.next()) |line| {
            assert(y < height);
            for (line) |c, x| {
                assert(x < width);
                map.values[y * width + x] = std.fmt.parseInt(u8, &[1]u8{c}, 10) catch unreachable;
            }
            y += 1;
        }
        return map;
    }

    pub fn getValue(self: *Self, x: i32, y: i32) ?u8 {
        if (x < 0 or y < 0) return null;
        if (x >= width or y >= height) return null;
        return self.values[@intCast(usize, y) * width + @intCast(usize, x)];
    }

    pub fn simulateStep(self: *Self) usize {
        std.mem.set(bool, &self.has_flashed, false);
        var num_flashes: usize = 0;

        // Add 1 energy level to all
        for (self.values) |*v| v.* += 1;

        // Check for flashes
        var continue_checking: bool = true;
        while (continue_checking) {
            continue_checking = false;

            var y: i32 = 0;
            while (y < height) : (y += 1) {
                var x: i32 = 0;
                while (x < width) : (x += 1) {
                    if (self.getValue(x, y)) |v| {
                        if (v > 9) {
                            var did_flash = self.flash(x, y);
                            if (did_flash) {
                                num_flashes += 1;
                                continue_checking = true;
                            }
                        }
                    }
                }
            }
        }

        // Set octopuses that flashed to 0
        for (self.has_flashed) |did_flash, i| {
            if (did_flash) self.values[i] = 0;
        }

        return num_flashes;
    }

    pub fn flash(self: *Self, x: i32, y: i32) bool {
        assert(x >= 0 and y >= 0);
        assert(x < width and y < height);

        if (self.has_flashed[@intCast(usize, y) * width + @intCast(usize, x)]) return false;

        self.has_flashed[@intCast(usize, y) * width + @intCast(usize, x)] = true;

        // Add energy to adjascent
        var by: i32 = y - 1;
        while (by <= y + 1) : (by += 1) {
            var bx: i32 = x - 1;
            while (bx <= x + 1) : (bx += 1) {
                if (bx < 0 or by < 0) continue;
                if (bx >= width or by >= height) continue;
                self.values[@intCast(usize, by) * width + @intCast(usize, bx)] += 1;
            }
        }

        return true;
    }

    pub fn print(self: *Self) void {
        var y: usize = 0;
        while (y < height) : (y += 1) {
            var x: usize = 0;
            while (x < width) : (x += 1) {
                std.debug.print("{d}\t", .{self.values[y * width + x]});
            }
            std.debug.print("\n", .{});
        }
    }
};

const example =
    \\5483143223
    \\2745854711
    \\5264556173
    \\6141336146
    \\6357385478
    \\4167524645
    \\2176841721
    \\6882881134
    \\4846848554
    \\5283751526
;

test "part 1" {
    var states = OctopusStates.fromStr(example);
    var sum_num_flashes: usize = 0;
    var i: usize = 0;
    while (i < 100) : (i += 1) {
        sum_num_flashes += states.simulateStep();
    }
    try testing.expectEqual(sum_num_flashes, 1656);
}

test "part 1" {
    var states = OctopusStates.fromStr(example);
    var i: usize = 0;
    while (i < 200) : (i += 1) {
        var num_flashes = states.simulateStep();
        if (num_flashes == 10 * 10) break;
    }
    try testing.expectEqual(i + 1, 195);
}
