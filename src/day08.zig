const std = @import("std");
const testing = std.testing;
const assert = std.debug.assert;

const log = std.log.scoped(.day08);

pub fn run() anyerror!void {
    var input_str = @embedFile("../data/day08_input.txt");
    var num_easy_digits: u32 = countNumberOfEasyDigits(input_str);
    log.info("Part 1: {d}", .{num_easy_digits});

    var sum: u32 = 0;
    var line_it = std.mem.tokenize(u8, input_str, "\n");
    while (line_it.next()) |line| {
        sum += deduceOutput(line);
    }
    log.info("Part 2: sum {d}", .{sum});
}

pub fn countNumberOfEasyDigits(input: []const u8) u32 {
    var it_line = std.mem.tokenize(u8, input, "|\n");
    var count: u32 = 0;
    var i: usize = 0;
    while (it_line.next()) |line| : (i += 1) {
        if (i % 2 == 0) continue; // Skip signal patterns

        var output_it = std.mem.tokenize(u8, line, " ");
        while (output_it.next()) |output| {
            if (output.len == 2 or // 1
                output.len == 3 or // 7
                output.len == 4 or // 4
                output.len == 7 // 8
            ) count += 1;
        }
    }

    return count;
}

//  aaaa
// b    c
// b    c
//  dddd
// e    f
// e    f
//  gggg
// We store these as bitset
// a b c d e f g -> (index) 0 1 2 3 4 5 6

const Signal = enum(u7) { a = 0b1000000, b = 0b0100000, c = 0b0010000, d = 0b0001000, e = 0b0000100, f = 0b0000010, g = 0b0000001 };

const original_digit_signals: [10]u7 = .{
    0b1110111, // 0: a,b,c,e,f,g
    0b0010010, // 1: c,f
    0b1011101, // 2: a,c,d,e,g
    0b1011011, // 3: a,c,d,f,g
    0b0111010, // 4: b,c,d,f
    0b1101011, // 5: a,b,d,f,g
    0b1101111, // 6: a,b,d,e,f,g
    0b1010010, // 7: a,c,f
    0b1111111, // 8: a,b,c,d,e,f,g
    0b1111011, // 9: a,b,c,d,f,g
};

fn signalStrToBitMap(signal: []const u8) u7 {
    var bitmap: u7 = 0b0000000;
    for (signal) |_, i| bitmap |= @enumToInt(std.meta.stringToEnum(Signal, signal[i .. i + 1]).?);
    return bitmap;
}

fn deduceOutput(signal_output_str: []const u8) u32 {
    var scrambled_digit_signals = [_]?u7{null} ** 10;

    var it = std.mem.tokenize(u8, signal_output_str, " |");
    var signals: [10]u7 = .{0} ** 10;
    {
        var i: usize = 0;
        while (i < 10) : (i += 1) signals[i] = signalStrToBitMap(it.next().?);
    }

    var output: [4]u7 = .{0} ** 4;
    {
        var i: usize = 0;
        while (i < 4) : (i += 1) output[i] = signalStrToBitMap(it.next().?);
    }

    var remaining_digits: usize = 10;

    while (remaining_digits > 0) {
        for (signals) |signal| {
            // Use length of signal to determine possible ...
            var decoded_digit: ?usize = null;
            switch (@popCount(u7, signal)) {
                2 => decoded_digit = 1,
                3 => decoded_digit = 7,
                4 => decoded_digit = 4,
                5 => {
                    // It could be either 2, 3 or 5.
                    // Intersect with signals we've already found, and see if we can deduce from that.
                    // 3 x 1 => 2 shared segments
                    // 2 x 4 => 2 shared segment
                    // 5 x 4 => 3 shared segments
                    if (scrambled_digit_signals[1]) |one| {
                        if (@popCount(u7, one & signal) == 2) {
                            decoded_digit = 3;
                        } else if (scrambled_digit_signals[4]) |four| {
                            if (@popCount(u7, four & signal) == 2) {
                                decoded_digit = 2;
                            } else if (@popCount(u7, four & signal) == 3) {
                                decoded_digit = 5;
                            }
                        }
                    }
                },
                6 => {
                    // It could be either 0, 6 or 9.
                    // Intersect with signals we've already found, and see if we can deduce from that.
                    // 6 x 1 => 1 shared segments
                    // 0 x 4 => 3 shared segments
                    // 9 x 4 => 5 shared segments
                    if (scrambled_digit_signals[1]) |one| {
                        if (@popCount(u7, one & signal) == 1) {
                            decoded_digit = 6;
                        } else if (scrambled_digit_signals[4]) |four| {
                            if (@popCount(u7, four & signal) == 3) {
                                decoded_digit = 0;
                            } else if (@popCount(u7, four & signal) == 4) {
                                decoded_digit = 9;
                            }
                        }
                    }
                },
                7 => decoded_digit = 8,
                else => unreachable,
            }

            if (decoded_digit != null and scrambled_digit_signals[decoded_digit.?] == null) {
                remaining_digits -= 1;
                scrambled_digit_signals[decoded_digit.?] = signal;
            }
        }
    }

    // Use mapping to translate output.
    var unscrambled_output: [4]u8 = undefined;
    for (output) |out_signal, i_out| {
        for (scrambled_digit_signals) |scrambled_signal_for_digit, i| {
            if (out_signal == scrambled_signal_for_digit) {
                unscrambled_output[i_out] = @intCast(u8, i);
            }
        }
    }

    var combined_output: u32 = 0;
    for (unscrambled_output) |o| {
        combined_output = combined_output * 10 + o;
    }
    return combined_output;
}

// [10 unique signal patterns] | [4 digit output]
const example =
    \\be cfbegad cbdgef fgaecd cgeb fdcge agebfd fecdb fabcd edb | fdgacbe cefdb cefbgd gcbe
    \\edbfga begcd cbg gc gcadebf fbgde acbgfd abcde gfcbed gfec | fcgedb cgb dgebacf gc
    \\fgaebd cg bdaec gdafb agbcfd gdcbef bgcad gfac gcb cdgabef | cg cg fdcagb cbg
    \\fbegcd cbd adcefb dageb afcb bc aefdc ecdab fgdeca fcdbega | efabcd cedba gadfec cb
    \\aecbfdg fbg gf bafeg dbefa fcge gcbea fcaegb dgceab fcbdga | gecf egdcabf bgf bfgea
    \\fgeab ca afcebg bdacfeg cfaedg gcfdb baec bfadeg bafgc acf | gebdcfa ecba ca fadegcb
    \\dbcfg fgd bdegcaf fgec aegbdf ecdfab fbedc dacgb gdcebf gf | cefg dcbef fcge gbcadfe
    \\bdfegc cbegaf gecbf dfcage bdacg ed bedf ced adcbefg gebcd | ed bcgafe cdgba cbgef
    \\egadfb cdbfeg cegd fecab cgb gbdefca cg fgcdab egfdb bfceg | gbdfcae bgc cg cgb
    \\gcafb gcf dcaebfg ecagb gf abcdeg gaef cafbge fdbac fegbdc | fgae cfgab fg bagce
;
var short_example = "acedgfb cdfbe gcdfa fbcad dab cefabd cdfgeb eafb cagedb ab | cdfeb fcadb cdfeb cdbaf";

test "part 1" {
    var num_easy_digits: u32 = countNumberOfEasyDigits(example);
    try testing.expectEqual(num_easy_digits, 26);
}

test "part 2" {
    var digits_short = deduceOutput(short_example);
    try testing.expectEqual(digits_short, 5353);

    var sum: u32 = 0;
    var line_it = std.mem.split(u8, example, "\n");
    while (line_it.next()) |line| {
        sum += deduceOutput(line);
    }
    try testing.expectEqual(sum, 61229);
}
