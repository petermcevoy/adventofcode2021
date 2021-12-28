const std = @import("std");
const testing = std.testing;
const fs = std.fs;
const io = std.io;

const log = std.log.scoped(.day02);

const SubmarineCommandError = error{
    UnknownCommand,
    ParseArgumentAsIntError,
};

const SubmarineCommand = enum {
    forward,
    backward,
    up,
    down,

    pub fn parseStr(str: []const u8, cmd: *SubmarineCommand, amount: *u32) SubmarineCommandError!void {
        var it = std.mem.tokenize(u8, str, " ");

        var cmdStr = it.next().?;
        if (std.mem.eql(u8, cmdStr, "forward")) {
            cmd.* = SubmarineCommand.forward;
        } else if (std.mem.eql(u8, cmdStr, "backward")) {
            cmd.* = SubmarineCommand.backward;
        } else if (std.mem.eql(u8, cmdStr, "up")) {
            cmd.* = SubmarineCommand.up;
        } else if (std.mem.eql(u8, cmdStr, "down")) {
            cmd.* = SubmarineCommand.down;
        } else {
            log.err("Unknown command: {s}", .{str});
            return SubmarineCommandError.UnknownCommand;
        }

        var amountStr = it.next().?;
        amount.* = std.fmt.parseInt(u32, amountStr, 10) catch {
            log.err("Could not parse argument as integer: {s}", .{str});
            return SubmarineCommandError.ParseArgumentAsIntError;
        };
    }
};

const SubmarineState = struct {
    hPos: u32,
    depth: u32,
    aim: u32,

    pub fn runCommandPart1(self: *SubmarineState, cmd: SubmarineCommand, amount: u32) !void {
        switch (cmd) {
            SubmarineCommand.forward => {
                self.hPos += amount;
            },
            SubmarineCommand.backward => {
                self.hPos -= amount;
            },
            SubmarineCommand.down => {
                self.depth += amount;
            },
            SubmarineCommand.up => {
                self.depth -= amount;
            },
        }
    }

    pub fn runCommandPart2(self: *SubmarineState, cmd: SubmarineCommand, amount: u32) !void {
        switch (cmd) {
            SubmarineCommand.forward => {
                self.hPos += amount;
                self.depth += self.aim * amount;
            },
            SubmarineCommand.backward => {
                self.hPos -= amount;
                self.depth -= self.aim * amount;
            },
            SubmarineCommand.down => {
                self.aim += amount;
            },
            SubmarineCommand.up => {
                self.aim -= amount;
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
    var lineBuffer: [1024:0]u8 = undefined;
    var cmd: SubmarineCommand = undefined;
    var amount: u32 = undefined;
    while (try reader.readUntilDelimiterOrEof(&lineBuffer, '\n')) |line| {
        try SubmarineCommand.parseStr(line, &cmd, &amount);
        try statePart1.runCommandPart1(cmd, amount);
        try statePart2.runCommandPart2(cmd, amount);
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
    const example_input =
        \\forward 5
        \\down 5
        \\forward 8
        \\up 3
        \\down 8
        \\forward 2
    ;
    var state = SubmarineState{ .hPos = 0, .depth = 0, .aim = 0 };
    var it = std.mem.split(u8, example_input, "\n");
    var cmd: SubmarineCommand = undefined;
    var amount: u32 = undefined;
    while (it.next()) |line| {
        try SubmarineCommand.parseStr(line, &cmd, &amount);
        try state.runCommandPart1(cmd, amount);
    }
    try testing.expectEqual(state.hPos, 15);
    try testing.expectEqual(state.depth, 10);
}

test "test part 2" {
    const example_input =
        \\forward 5
        \\down 5
        \\forward 8
        \\up 3
        \\down 8
        \\forward 2
    ;
    var state = SubmarineState{ .hPos = 0, .depth = 0, .aim = 0 };
    var it = std.mem.split(u8, example_input, "\n");
    var cmd: SubmarineCommand = undefined;
    var amount: u32 = undefined;
    while (it.next()) |line| {
        try SubmarineCommand.parseStr(line, &cmd, &amount);
        try state.runCommandPart2(cmd, amount);
    }
    try testing.expectEqual(state.hPos, 15);
    try testing.expectEqual(state.aim, 10);
    try testing.expectEqual(state.depth, 60);
}
