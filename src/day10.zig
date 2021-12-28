const std = @import("std");
const testing = std.testing;
const assert = std.debug.assert;
const log = std.log.scoped(.day10);

pub fn run() anyerror!void {
    var input_str = @embedFile("../data/day10_input.txt");
    var line_it = std.mem.tokenize(u8, input_str, "\n");

    var score_corrupt: u64 = 0;

    var num_fix_scores: usize = 0;
    var score_fix_buffer = [_]u64{0} ** 100;
    var buffer: [16]u8 = undefined;
    while (line_it.next()) |line| {
        if (findCorruptingChar(line)) |c| {
            score_corrupt += getIllegalCharScore(c);
        }

        if (fixIncompleteLine(line, &buffer)) |completing_chars| {
            for (completing_chars) |c| {
                score_fix_buffer[num_fix_scores] = score_fix_buffer[num_fix_scores] * 5 + getFixCharScore(c);
            }
            num_fix_scores += 1;
        }
    }
    log.info("Part 1: score_corrupt {d}", .{score_corrupt});

    std.sort.sort(u64, score_fix_buffer[0..num_fix_scores], {}, comptime std.sort.asc(u64));
    log.info("Part 2: score_fix {d}", .{score_fix_buffer[num_fix_scores / 2]});
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

pub fn getIllegalCharScore(c: u8) u32 {
    return switch (c) {
        ')' => 3,
        ']' => 57,
        '}' => 1197,
        '>' => 25137,
        else => unreachable,
    };
}

pub fn getFixCharScore(c: u8) u64 {
    return switch (c) {
        ')' => 1,
        ']' => 2,
        '}' => 3,
        '>' => 4,
        else => unreachable,
    };
}

const stack_size = 16;
pub fn processChars(str: []const u8, char_stack: *[stack_size]?u8) ?u8 {
    char_stack.* = [_]?u8{null} ** stack_size;
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
                var latest_opening = char_stack[i_stack].?;
                char_stack[i_stack] = null;

                var expected_closing = getMatchingClosingChar(latest_opening);
                if (c != expected_closing) return c; // Found illegal char!
            },
            else => unreachable,
        }

        assert(i_stack < stack_size);
    }
    return null;
}

pub fn findCorruptingChar(str: []const u8) ?u8 {
    var char_stack = [_]?u8{null} ** stack_size;
    var illegal_char: ?u8 = processChars(str, &char_stack);
    return illegal_char;
}

pub fn fixIncompleteLine(str: []const u8, buffer: *[16]u8) ?[]u8 {
    var char_stack = [_]?u8{0} ** stack_size;
    var illegal_char = processChars(str, &char_stack);
    if (illegal_char != null) return null; // Can't fix, the chunk is illegal.

    var i: usize = 0;
    var num_chars: usize = 0;
    while (i < 16) : (i += 1) {
        if (char_stack[15 - i]) |c| {
            (buffer.*)[num_chars] = getMatchingClosingChar(c);
            num_chars += 1;
        }
    }

    return if (num_chars > 0) buffer[0..num_chars] else null;
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

    var line_it = std.mem.tokenize(u8, example, "\n");
    var score: u32 = 0;
    var i: usize = 0;
    while (line_it.next()) |line| {
        var char = findCorruptingChar(line);
        try testing.expectEqual(char, exptected_illegal_chars[i]);
        if (char) |c| score += getIllegalCharScore(c);
        i += 1;
    }
    try testing.expectEqual(score, 26397);
}

test "part 2" {
    var line_it = std.mem.tokenize(u8, example, "\n");
    var buffer: [16]u8 = undefined;
    try testing.expectEqualStrings(fixIncompleteLine(line_it.next().?, &buffer).?, "}}]])})]");
    try testing.expectEqualStrings(fixIncompleteLine(line_it.next().?, &buffer).?, ")}>]})");
    try testing.expectEqual(fixIncompleteLine(line_it.next().?, &buffer), null);
    try testing.expectEqualStrings(fixIncompleteLine(line_it.next().?, &buffer).?, "}}>}>))))");
    try testing.expectEqual(fixIncompleteLine(line_it.next().?, &buffer), null);
    try testing.expectEqual(fixIncompleteLine(line_it.next().?, &buffer), null);
    try testing.expectEqualStrings(fixIncompleteLine(line_it.next().?, &buffer).?, "]]}}]}]}>");
    try testing.expectEqual(fixIncompleteLine(line_it.next().?, &buffer), null);
    try testing.expectEqual(fixIncompleteLine(line_it.next().?, &buffer), null);
    try testing.expectEqualStrings(fixIncompleteLine(line_it.next().?, &buffer).?, "])}>");
}
