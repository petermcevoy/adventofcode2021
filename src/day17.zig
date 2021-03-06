const std = @import("std");
const testing = std.testing;
const stdout = std.io.getStdOut().writer();

pub fn run() anyerror!void {
    var input_str = @embedFile("../data/day17_input.txt");
    var area = TargetArea.fromStr(input_str);

    // Part 1: Find highest y position.
    var y_initial = -area.y0 - 1;
    // Y is updated like the triangular number 9+8+7+...+1 = n*(n+1)/2
    var y_max = @divExact(y_initial * (y_initial + 1), 2);
    try stdout.print("Part 1: {d}\n", .{y_max});

    // Part 2: Count candidate inital velocities
    var count = countCandateInitialVels(&area);
    try stdout.print("Part 2: {d}\n", .{count});
}

const TargetArea = struct {
    x0: i64,
    x1: i64,
    y0: i64,
    y1: i64,

    pub fn fromStr(str: []const u8) @This() {
        var area = TargetArea{
            .x0 = undefined,
            .x1 = undefined,
            .y0 = undefined,
            .y1 = undefined,
        };
        var it = std.mem.tokenize(u8, str, " =,.\n");
        _ = it.next().?; // target
        _ = it.next().?; // area:
        _ = it.next().?; // x
        area.x0 = std.fmt.parseInt(i32, it.next().?, 10) catch unreachable;
        area.x1 = std.fmt.parseInt(i32, it.next().?, 10) catch unreachable;
        _ = it.next().?; // y
        area.y0 = std.fmt.parseInt(i32, it.next().?, 10) catch unreachable;
        area.y1 = std.fmt.parseInt(i32, it.next().?, 10) catch unreachable;
        return area;
    }
};

const ProbeState = struct {
    x: i64,
    y: i64,
    vel_x: i64,
    vel_y: i64,

    pub fn simulteStep(self: *@This()) void {
        self.x += self.vel_x;
        self.y += self.vel_y;
        if (self.vel_x > 0) {
            self.vel_x += -1;
        } else if (self.vel_x < 0) {
            self.vel_x += 1;
        }
        self.vel_y += -1;
        //std.debug.print("Simulated Probe:\n{s}\n\n", .{self});
    }
};

pub fn doesHitTarget(target: *const TargetArea, vx: i64, vy: i64) bool {
    var probe = ProbeState{
        .x = 0,
        .y = 0,
        .vel_x = vx,
        .vel_y = vy,
    };

    while (probe.vel_x > 0) {
        probe.simulteStep();

        // Check if we overshot the target in x or are below in y
        if (probe.x > target.x1 or probe.y < target.y0) return false;

        // Check if we are in target
        if (probe.x >= target.x0 and probe.y <= target.y1) return true;
    }

    // At this stage we have no more x motion.
    if (probe.x < target.x0 or probe.x > target.x1) return false;

    while (true) {
        probe.simulteStep();
        if (probe.y <= target.y1 and probe.y >= target.y0) {
            return true;
        } else if (probe.y <= target.y0) return false;
    }

    unreachable;
}

pub fn countCandateInitialVels(area: *const TargetArea) usize {
    var initial_vels_count: usize = 0;
    var max_initial_y_vel = -area.y0 - 1;
    var iy: i64 = area.y0;
    while (iy <= max_initial_y_vel) : (iy += 1) {
        var ix: i64 = 1; // asume that x is positive
        while (ix <= area.x1) : (ix += 1) {
            if (doesHitTarget(area, ix, iy)) initial_vels_count += 1;
        }
    }
    return initial_vels_count;
}

test "common" {
    var area = TargetArea.fromStr("target area: x=20..30, y=-10..-5");
    try testing.expectEqual(area.x0, 20);
    try testing.expectEqual(area.x1, 30);
    try testing.expectEqual(area.y0, -10);
    try testing.expectEqual(area.y1, -5);

    var probe = ProbeState{
        .x = 0,
        .y = 0,
        .vel_x = 7,
        .vel_y = 2,
    };
    var i: usize = 0;
    while (i < 7) : (i += 1) probe.simulteStep();
    try testing.expectEqual(probe.x, 28);
    try testing.expectEqual(probe.y, -7);

    try testing.expectEqual(doesHitTarget(&area, 7, 2), true);
    try testing.expectEqual(doesHitTarget(&area, 6, 3), true);
    try testing.expectEqual(doesHitTarget(&area, 9, 0), true);
    try testing.expectEqual(doesHitTarget(&area, 17, -4), false);
}

test "part 1" {
    var area = TargetArea.fromStr("target area: x=20..30, y=-10..-5");

    // Find highest y position.
    var y_initial = -area.y0 - 1;
    var y_max = @divExact(y_initial * (y_initial + 1), 2);
    try testing.expectEqual(y_max, 45);
}

test "part 2" {
    var area = TargetArea.fromStr("target area: x=20..30, y=-10..-5");

    var count = countCandateInitialVels(&area);
    try testing.expectEqual(count, 112);
}
