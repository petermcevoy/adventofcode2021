const std = @import("std");
const testing = std.testing;
const assert = std.debug.assert;
const log = std.log.scoped(.day14);

pub fn run() anyerror!void {
    var input_str = @embedFile("../data/day14_input.txt");
    var rules_buffer: [100]InsertionRule = undefined;
    var result_buffer: [max_len]u8 = undefined;
    var template = std.mem.tokenize(input_str, "\n").next().?;
    var rules = parseInsertionRulesFromStr(&rules_buffer, input_str[std.mem.indexOf(u8, input_str, "\n").?..]);

    var i: usize = 0;
    while (i < 10) : (i += 1) {
        template = processStep(&result_buffer, rules, template);
    }

    var most_common_count: u32 = undefined;
    var least_common_count: u32 = undefined;
    _ = getElementCounts(template, &most_common_count, &least_common_count);

    log.info("Part 1: {d}", .{most_common_count - least_common_count});
}

const max_len = 20_000;
pub fn processStep(buffer: []u8, rules: []InsertionRule, template: []const u8) []const u8 {
    // template could be a slice into the buffer, we copy it just to be sure...
    var template_copy_buffer: [max_len]u8 = undefined;
    std.mem.copy(u8, &template_copy_buffer, template);
    var template_copy = template_copy_buffer[0..template.len];

    // Go through template and process
    var i_template: usize = 0;
    var i_new: usize = 0;
    while (i_template < template_copy.len) : (i_template += 1) {
        var c: u8 = template_copy[i_template];
        var c_next: ?u8 = if (i_template + 1 == template_copy.len) null else template_copy[i_template + 1];

        buffer[i_new] = c;
        i_new += 1;

        if (c_next == null) continue;

        for (rules) |r| {
            if (std.mem.eql(u8, &r.pair, &[2]u8{ c, c_next.? })) {
                // Insert the new char
                buffer[i_new] = r.result;
                i_new += 1;
            }
        }
        buffer[i_new] = c_next.?;
    }

    return buffer[0..i_new];
}

const InsertionRule = struct {
    pair: [2]u8,
    result: u8,

    pub fn fromStr(str: []const u8) @This() {
        var it = std.mem.split(str, " -> ");
        var rule: InsertionRule = undefined;
        rule.pair = it.next().?[0..2].*;
        rule.result = it.next().?[0];

        return rule;
    }
};

pub fn parseInsertionRulesFromStr(buffer: []InsertionRule, str: []const u8) []InsertionRule {
    var num_rules: usize = 0;
    var it = std.mem.tokenize(str, "\n");
    while (it.next()) |line| {
        buffer[num_rules] = InsertionRule.fromStr(line);
        num_rules += 1;
    }

    return buffer[0..num_rules];
}

pub fn getElementCounts(buffer: []const u8, most_common_count: ?*u32, least_common_count: ?*u32) [26]u32 {
    var counts = [_]u32{0} ** 26;
    for (buffer) |c| {
        var index = c - 'A';
        counts[index] += 1;
    }

    if (least_common_count != null or most_common_count != null) {
        var counts_sorted: [26]u32 = undefined;
        std.mem.copy(u32, &counts_sorted, &counts);
        std.sort.sort(u32, &counts_sorted, {}, comptime std.sort.asc(u32));
        if (most_common_count) |pcount| {
            pcount.* = counts_sorted[25];
        }
        if (least_common_count) |pcount| {
            for (counts_sorted) |c| {
                if (c > 0) {
                    pcount.* = c;
                    break;
                }
            }
        }
    }

    return counts;
}

const example =
    \\NNCB
    \\
    \\CH -> B
    \\HH -> N
    \\CB -> H
    \\NH -> C
    \\HB -> C
    \\HC -> B
    \\HN -> C
    \\NN -> C
    \\BH -> H
    \\NC -> B
    \\NB -> B
    \\BN -> B
    \\BB -> N
    \\BC -> B
    \\CC -> N
    \\CN -> C
;

test "part 1" {
    var template = std.mem.tokenize(example, "\n").next().?;
    var rules_buffer: [100]InsertionRule = undefined;
    var rules = parseInsertionRulesFromStr(&rules_buffer, example[std.mem.indexOf(u8, example, "\n").?..]);
    var result_buffer: [max_len]u8 = undefined;
    var result = processStep(&result_buffer, rules, template);
    try testing.expectEqualStrings(result, "NCNBCHB");
    result = processStep(&result_buffer, rules, result);
    try testing.expectEqualStrings(result, "NBCCNBBBCBHCB");

    var i: usize = 2;
    while (i < 10) : (i += 1) {
        result = processStep(&result_buffer, rules, result);
    }

    var most_common_count: u32 = undefined;
    var least_common_count: u32 = undefined;
    _ = getElementCounts(result, &most_common_count, &least_common_count);
    try testing.expectEqual(most_common_count, 1749);
    try testing.expectEqual(least_common_count, 161);
}
