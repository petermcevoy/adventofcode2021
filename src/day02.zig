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

    pub fn readCommandStr(self: *SubmarineState, commandStr: []const u8) !void {
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
};

pub fn run() anyerror!void {
    const filepath = "data/day02_input.txt";
    var f = try fs.cwd().openFile(filepath, fs.File.OpenFlags{ .read = true });
    defer f.close();

    var bufferedReader = io.bufferedReader(f.reader());
    var reader = bufferedReader.reader();

    // Initial state
    var state = SubmarineState{ .hPos = 0, .depth = 0 };

    // Process commands
    var lineBuffer: [1024]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(&lineBuffer, '\n')) |line| {
        try state.readCommandStr(line);
    }

    log.info("Part 1:\tSubmarine horizontal pos: {d}", .{state.hPos});
    log.info("\t\tSubmarine depth: {d}", .{state.depth});
    log.info("\t\tProduct: {d}", .{state.hPos * state.depth});
}

test "test part 1" {
    var state = SubmarineState{ .hPos = 0, .depth = 0 };
    try state.readCommandStr("forward 5");
    try state.readCommandStr("down 5");
    try state.readCommandStr("forward 8");
    try state.readCommandStr("up 3");
    try state.readCommandStr("down 8");
    try state.readCommandStr("forward 2");
    try testing.expectEqual(state.hPos, 15);
    try testing.expectEqual(state.depth, 10);
}
