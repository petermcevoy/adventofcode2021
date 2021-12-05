const std = @import("std");
const testing = std.testing;
const fs = std.fs;
const io = std.io;

const log = std.log.scoped(.day02);

const SubmarineCommandError = error{UnknownCommand};

const SubmarineCommand = enum {
    forward,
    backward,
    up,
    down,

    pub fn parseStr(str: []const u8) !SubmarineCommand {
        if (std.mem.eql(u8, str, "forward")) {
            return SubmarineCommand.forward;
        } else if (std.mem.eql(u8, str, "backward")) {
            return SubmarineCommand.backward;
        } else if (std.mem.eql(u8, str, "up")) {
            return SubmarineCommand.up;
        } else if (std.mem.eql(u8, str, "down")) {
            return SubmarineCommand.down;
        } else {
            log.err("Unknown command: {s}", .{str});
            return SubmarineCommandError.UnknownCommand;
        }
    }
};

const SubmarineState = struct {
    hPos: u32,
    depth: u32,
    aim: u32,

    pub fn readCommandStrPart1(self: *SubmarineState, commandStr: []const u8) !void {
        var it = std.mem.tokenize(commandStr, " ");
        var command: SubmarineCommand = try SubmarineCommand.parseStr(it.next().?);
        var argument = try std.fmt.parseInt(u32, it.next().?, 10);

        switch (command) {
            SubmarineCommand.forward => {
                self.hPos += argument;
            },
            SubmarineCommand.backward => {
                self.hPos -= argument;
            },
            SubmarineCommand.down => {
                self.depth += argument;
            },
            SubmarineCommand.up => {
                self.depth -= argument;
            },
        }
    }

    pub fn readCommandStrPart2(self: *SubmarineState, commandStr: []const u8) !void {
        var it = std.mem.tokenize(commandStr, " ");
        var command: SubmarineCommand = try SubmarineCommand.parseStr(it.next().?);
        var argument = try std.fmt.parseInt(u32, it.next().?, 10);

        switch (command) {
            SubmarineCommand.forward => {
                self.hPos += argument;
                self.depth += self.aim * argument;
            },
            SubmarineCommand.backward => {
                self.hPos -= argument;
                self.depth -= self.aim * argument;
            },
            SubmarineCommand.down => {
                self.aim += argument;
            },
            SubmarineCommand.up => {
                self.aim -= argument;
            },
        }
    }
};

pub fn run() anyerror!void {
    const filepath = "data/day02_input.txt";
    var f = try fs.cwd().openFile(filepath, fs.File.OpenFlags{ .read = true });
    defer f.close();

    var bufferedReader = io.bufferedReader(f.reader());
    var reader = bufferedReader.reader();

    // Initial state
    var statePart1 = SubmarineState{ .hPos = 0, .depth = 0, .aim = 0 };
    var statePart2 = SubmarineState{ .hPos = 0, .depth = 0, .aim = 0 };

    // Process commands
    var lineBuffer: [1024]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(&lineBuffer, '\n')) |line| {
        try statePart1.readCommandStrPart1(line);
        try statePart2.readCommandStrPart2(line);
    }

    log.info("Part 1:\tSubmarine horizontal pos: {d}", .{statePart1.hPos});
    log.info("\t\tSubmarine depth: {d}", .{statePart1.depth});
    log.info("\t\tProduct hPos*depth: {d}", .{statePart1.hPos * statePart1.depth});

    log.info("Part 2:\tSubmarine horizontal pos: {d}", .{statePart2.hPos});
    log.info("\t\tSubmarine depth: {d}", .{statePart2.depth});
    log.info("\t\tSubmarine aim: {d}", .{statePart2.aim});
    log.info("\t\tProduct hPos*depth: {d}", .{statePart2.hPos * statePart2.depth});
}

test "test part 1" {
    var state = SubmarineState{ .hPos = 0, .depth = 0, .aim = 0 };
    try state.readCommandStrPart1("forward 5");
    try state.readCommandStrPart1("down 5");
    try state.readCommandStrPart1("forward 8");
    try state.readCommandStrPart1("up 3");
    try state.readCommandStrPart1("down 8");
    try state.readCommandStrPart1("forward 2");
    try testing.expectEqual(state.hPos, 15);
    try testing.expectEqual(state.depth, 10);
}

test "test part 2" {
    var state = SubmarineState{ .hPos = 0, .depth = 0, .aim = 0 };
    try state.readCommandStrPart2("forward 5");
    try state.readCommandStrPart2("down 5");
    try state.readCommandStrPart2("forward 8");
    try state.readCommandStrPart2("up 3");
    try state.readCommandStrPart2("down 8");
    try state.readCommandStrPart2("forward 2");
    try testing.expectEqual(state.hPos, 15);
    try testing.expectEqual(state.aim, 10);
    try testing.expectEqual(state.depth, 60);
}
