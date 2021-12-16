const std = @import("std");
const testing = std.testing;
const assert = std.debug.assert;
const log = std.log.scoped(.day10);

pub fn run() anyerror!void {
    var input_str = @embedFile("../data/day10_input.txt");
    var line_it = std.mem.tokenize(input_str, "\n");
    var score: u32 = 0;
    while (line_it.next()) |line| {
        if (findCorruptingChar(line)) |c| {
            score += getCharScore(c);
        }
    }
    log.info("Part 1: score {d}", .{score});
}

const CharType = enum { opening, closing, unknown };
const opening_chars = "({[<";
const closing_chars = ")}]>";

pub fn getMatchingClosingChar(c: u8) u8 {
    return switch (c) {
        '(' => ')',
        '[' => ']',
        '{' => '}',
        '<' => '>',
        else => unreachable,
    };
}

pub fn getCharScore(c: u8) u32 {
    return switch (c) {
        ')' => 3,
        ']' => 57,
        '}' => 1197,
        '>' => 25137,
        else => unreachable,
    };
}

pub fn findCorruptingChar(str: []const u8) ?u8 {
    const stack_size = 16;
    var char_stack = [_]u8{0} ** stack_size;
    var i_stack: usize = 0;

    for (str) |c| {
        var char_type: CharType = .unknown;

        for (opening_chars) |cmp| {
            if (cmp == c) {
                char_type = .opening;
                break;
            }
        }
        if (char_type == .unknown) {
            for (closing_chars) |cmp| {
                if (cmp == c) {
                    char_type = .closing;
                    break;
                }
            }
        }

        switch (char_type) {
            .opening => {
                char_stack[i_stack] = c;
                i_stack += 1;
            },
            .closing => {
                i_stack -= 1;
                var latest_opening = char_stack[i_stack];
                var expected_closing = getMatchingClosingChar(latest_opening);
                if (c != expected_closing) return c; // Found illegal char!
            },
            else => unreachable,
        }

        assert(i_stack < stack_size);
    }
    // No errors for input!
    return null;
}

const example =
    \\[({(<(())[]>[[{[]{<()<>>
    \\[(()[<>])]({[<{<<[]>>(
    \\{([(<{}[<>[]}>{[]{[(<()>
    \\(((({<>}<{<{<>}{[]{[]{}
    \\[[<[([]))<([[{}[[()]]]
    \\[{[{({}]{}}([{[{{{}}([]
    \\{<[[]]>}<{[{[{[]{()[[[]
    \\[<(<(<(<{}))><([]([]()
    \\<{([([[(<>()){}]>(<<{{
    \\<{([{{}}[<[[[<>{}]]]>[]]
;

test "part 1" {
    const exptected_illegal_chars: [10]?u8 = .{ null, null, '}', null, ')', ']', null, ')', '>', null };

    var line_it = std.mem.tokenize(example, "\n");
    var score: u32 = 0;
    var i: usize = 0;
    while (line_it.next()) |line| {
        var char = findCorruptingChar(line);
        try testing.expectEqual(char, exptected_illegal_chars[i]);
        if (char) |c| score += getCharScore(c);
        i += 1;
    }
    try testing.expectEqual(score, 26397);
}
