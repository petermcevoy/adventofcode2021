const std = @import("std");
const testing = std.testing;
const assert = std.debug.assert;

const log = std.log.scoped(.day08);

pub fn run() anyerror!void {
    var input_str = @embedFile("../data/day08_input.txt");
    var num_easy_digits: u32 = countNumberOfEasyDigits(input_str);
    log.info("Part 1: {d}", .{num_easy_digits});

    _ = crackSegmentMapping(short_example);
    //var a: [7]u8 = .{ 0, 1, 2, 3, 4, 5, 6 };
    //var i: usize = 0;
    //while (i < 12) : (i += 1) {
    //    generatePermutation(7, &a);
    //    for (a) |v| std.debug.print(" {d}", .{v});
    //    std.debug.print("\n", .{});
    //}
}

pub fn countNumberOfEasyDigits(input: []const u8) u32 {
    var it_line = std.mem.tokenize(input, "|\n");
    var count: u32 = 0;
    var i: usize = 0;
    while (it_line.next()) |line| : (i += 1) {
        if (i % 2 == 0) continue; // Skip signal patterns

        var output_it = std.mem.tokenize(line, " ");
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
// a b c d e f g -> 0 1 2 3 4 5 6

const Signal = enum {
    a,
    b,
    c,
    d,
    e,
    f,
    g,

    pub fn fromChar(char: u8) Signal {
        return switch (char) {
            'a' => .a,
            'b' => .b,
            'c' => .c,
            'd' => .d,
            'e' => .e,
            'f' => .f,
            'g' => .g,
            else => unreachable,
        };
    }

    pub fn asBitCode(self: Signal) u7 {
        return switch (self) {
            .a => 0b1000000,
            .b => 0b0100000,
            .c => 0b0010000,
            .d => 0b0001000,
            .e => 0b0000100,
            .f => 0b0000010,
            .g => 0b0000001,
        };
    }
};

const segments_used_in_digit: [10]u7 = .{
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

    for (signal) |char, i| {
        bitmap |= @enumToInt(std.meta.stringToEnum(Signal, signal[i .. i + 1]).?);
    }
    return bitmap;
}

// Heap's algorithm
// https://en.wikipedia.org/wiki/Heap's_algorithm
pub fn generatePermutation(k: usize, a: []u8) void {
    if (k == 1) return;

    generatePermutation(k - 1, a);

    var i: usize = 0;
    while (i < k - 1) : (i += 1) {
        if (k % 2 == 0) {
            std.mem.swap(u8, &a[i], &a[k - 1]);
        } else {
            std.mem.swap(u8, &a[0], &a[k - 1]);
        }
        generatePermutation(k - 1, a);
    }
}

fn mapSignal(signal: u7, mapping: [7]u8) u7 {
    var mapped_signal: u7 = 0;

    mapped_signal |= (signal & Signal.a.asBitCode()) >> @intCast(u3, mapping[0]);
    mapped_signal |= (signal & Signal.b.asBitCode()) >> @intCast(u3, mapping[1]);
    mapped_signal |= (signal & Signal.c.asBitCode()) >> @intCast(u3, mapping[2]);
    mapped_signal |= (signal & Signal.d.asBitCode()) >> @intCast(u3, mapping[3]);
    mapped_signal |= (signal & Signal.e.asBitCode()) >> @intCast(u3, mapping[4]);
    mapped_signal |= (signal & Signal.f.asBitCode()) >> @intCast(u3, mapping[5]);
    mapped_signal |= (signal & Signal.g.asBitCode()) >> @intCast(u3, mapping[6]);

    return mapped_signal;
}

fn crackSegmentMapping(signal_output_str: []const u8) void {
    var it = std.mem.tokenize(signal_output_str, " |");

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

    // Iterate over possible mappings.
    var mapping: [7]u8 = .{ 0, 1, 2, 3, 4, 5, 6 };

    var i_mapping: usize = 0;
    while (i_mapping < 7 * 6 * 5 * 4 * 3 * 2 * 1) : (i_mapping += 1) {
        for (mapping) |m| std.debug.print("{d} ", .{m});
        std.debug.print("\n", .{});
        for (signals) |signal| {
            var easy_digit: ?u8 = switch (@popCount(u7, signal)) {
                2 => 1,
                3 => 7,
                4 => 4,
                7 => 8,
                else => null,
            };

            if (easy_digit != null) {
                // map signal and compare with segment
                var mapped_signal = mapSignal(signal, mapping);
                for (segments_used_in_digit) |expected_signal| {
                    log.info("0b{b:0>7} -> 0b{b:0>7}", .{ signal, mapped_signal });
                    if (mapped_signal == expected_signal) {
                        log.info("match! 0b{b:0>7} -> 0b{b:0>7}", .{ signal, mapped_signal });
                    }
                }
            }
        }

        // Try if this mapping works...
        generatePermutation(7, &mapping);
    }

    // mapping {1,2,3,4}
    // mapping {2,1,3,4}

    //while (it.next()) |signal| {
    //    // Find the digits we can deduce based only on len.
    //    var easy_digit: ?u8 = switch (signal.len) {
    //        2 => 1,
    //        3 => 7,
    //        4 => 4,
    //        7 => 8,
    //        else => null,
    //    };
    //    log.info("{s}\t: 0b{b:0>7} ({d})", .{ signal, signalStrToBitMap(signal), easy_digit });

    //    // Try to find another signal that matches in all bits except for one.
    //}

    // Intersect the bits for the easy digits""

    //for (mapping) |m, i| log.info("{} -> {d} ", .{ m, i });

    //var signals_str = it.next();
    //var output_digits_str = it.next();

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

test "part 1" {
    var num_easy_digits: u32 = countNumberOfEasyDigits(example);
    try testing.expectEqual(num_easy_digits, 26);
}

test "mapping" {
    var r = mapSignal(0b1000000, [_]u8{ 2, 1, 0, 3, 4, 5, 6 });
    std.debug.print("{b:0>7}", .{r});
    try testing.expectEqual(r, 0b0010000);
}

var short_example_easy = "ab dab | cdbaf";
var short_example = "acedgfb cdfbe gcdfa fbcad dab cefabd cdfgeb eafb cagedb ab | cdfeb fcadb cdfeb cdbaf";
test "part 2" {
    //var num_easy_digits: u32 = countNumberOfEasyDigits(example);
    //try testing.expectEqual(, 5353);
    //try testing.expectEqual(, 61229);
}
