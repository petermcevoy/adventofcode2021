const std = @import("std");
const testing = std.testing;
const assert = std.debug.assert;
const log = std.log.scoped(.day14);

pub fn run() anyerror!void {
    var input_str = @embedFile("../data/day14_input.txt");
    var rules_buffer: [100]InsertionRule = undefined;
    var rules = parseInsertionRulesFromStr(&rules_buffer, input_str[std.mem.indexOf(u8, input_str, "\n").?..]);
    var template = std.mem.tokenize(u8, input_str, "\n").next().?;
    var state = makeStateFromTemplate(template);

    var i: usize = 0;
    while (i < 10) : (i += 1) processStep(&state, rules);
    log.info("Part 1: {d}", .{calcAnswer(state.counts)});

    while (i < 40) : (i += 1) processStep(&state, rules);
    log.info("Part 2: {d}", .{calcAnswer(state.counts)});
}

const State = struct { pairs: [26][26]u64, counts: [26]u64 };

pub fn makeStateFromTemplate(template: []const u8) State {
    var state = State{
        .pairs = .{.{0} ** 26} ** 26,
        .counts = .{0} ** 26,
    };

    var i_template: usize = 0;
    while (i_template < template.len) : (i_template += 1) {
        var c: u8 = template[i_template];
        var c_next: ?u8 = if (i_template + 1 == template.len) null else template[i_template + 1];

        var index1 = c - @intCast(usize, 'A');
        state.counts[index1] += 1;

        if (c_next == null) continue;
        var index2 = c_next.? - @intCast(usize, 'A');
        state.pairs[index1][index2] += 1;
    }

    return state;
}

pub fn processStep(state: *State, rules: []InsertionRule) void {
    var state_pairs_copy: [26][26]u64 = state.pairs;

    var i_c1: usize = 0;
    while (i_c1 < 26) : (i_c1 += 1) {
        var c1: u8 = @intCast(u8, i_c1) + 'A';
        var i_c2: usize = 0;
        while (i_c2 < 26) : (i_c2 += 1) {
            if (state_pairs_copy[i_c1][i_c2] == 0) continue;
            var c2: u8 = @intCast(u8, i_c2) + 'A';
            for (rules) |r| {
                if (std.mem.eql(u8, &r.pair, &[2]u8{ c1, c2 })) {
                    // Where adding a new element based on the rule.
                    var i_c_new = r.result - 'A';

                    // Add the new pairs
                    state.pairs[i_c1][i_c_new] += state_pairs_copy[i_c1][i_c2];
                    state.pairs[i_c_new][i_c2] += state_pairs_copy[i_c1][i_c2];

                    // By inserting a new charachter inbetween, we have split the previous pair.
                    state.pairs[i_c1][i_c2] -= state_pairs_copy[i_c1][i_c2];

                    // Keep track of the number of elemnts.
                    state.counts[i_c_new] += state_pairs_copy[i_c1][i_c2];
                }
            }
        }
    }
}

const InsertionRule = struct {
    pair: [2]u8,
    result: u8,

    pub fn fromStr(str: []const u8) @This() {
        var it = std.mem.split(u8, str, " -> ");
        var rule: InsertionRule = undefined;
        rule.pair = it.next().?[0..2].*;
        rule.result = it.next().?[0];

        return rule;
    }
};

pub fn parseInsertionRulesFromStr(buffer: []InsertionRule, str: []const u8) []InsertionRule {
    var num_rules: usize = 0;
    var it = std.mem.tokenize(u8, str, "\n");
    while (it.next()) |line| {
        buffer[num_rules] = InsertionRule.fromStr(line);
        num_rules += 1;
    }

    return buffer[0..num_rules];
}

pub fn calcAnswer(counts: [26]u64) u64 {
    var most_common_count: u64 = 0;
    var least_common_count: u64 = 0;

    var counts_sorted: [26]u64 = undefined;
    std.mem.copy(u64, &counts_sorted, &counts);
    std.sort.sort(u64, &counts_sorted, {}, comptime std.sort.asc(u64));
    most_common_count = counts_sorted[25];
    for (counts_sorted) |c| {
        if (c > 0) {
            least_common_count = c;
            break;
        }
    }

    return most_common_count - least_common_count;
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
    var template = std.mem.tokenize(u8, example, "\n").next().?;
    var rules_buffer: [100]InsertionRule = undefined;
    var rules = parseInsertionRulesFromStr(&rules_buffer, example[std.mem.indexOf(u8, example, "\n").?..]);

    var state = makeStateFromTemplate(template); // NNCB
    try testing.expectEqualSlices(u64, &state.counts, &.{ 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 });

    var i: usize = 0;
    std.debug.print("\nProcessing it 1\n", .{});
    processStep(&state, rules); // NCNBCHB
    i += 1;
    try testing.expectEqualSlices(u64, &state.counts, &.{ 0, 2, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 });

    std.debug.print("\nProcessing it 2\n", .{});
    processStep(&state, rules); // NBCCNBBBCBHCB
    i += 1;
    try testing.expectEqualSlices(u64, &state.counts, &.{ 0, 6, 4, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 });

    std.debug.print("\nProcessing it 3\n", .{});
    processStep(&state, rules); // NBBBCNCCNBBNBNBBCHBHHBCHB
    i += 1;
    try testing.expectEqualSlices(u64, &state.counts, &.{ 0, 11, 5, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 });

    while (i < 10) : (i += 1) processStep(&state, rules);
    try testing.expectEqual(calcAnswer(state.counts), 1749 - 161);
}

test "part 2" {
    var template = std.mem.tokenize(u8, example, "\n").next().?;
    var rules_buffer: [100]InsertionRule = undefined;
    var rules = parseInsertionRulesFromStr(&rules_buffer, example[std.mem.indexOf(u8, example, "\n").?..]);

    var state = makeStateFromTemplate(template); // NNCB
    var i: usize = 0;
    while (i < 40) : (i += 1) processStep(&state, rules);
    try testing.expectEqual(calcAnswer(state.counts), 2188189693529);
}
