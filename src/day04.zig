const std = @import("std");
const testing = std.testing;
const assert = std.debug.assert;

const log = std.log.scoped(.day04);

const BingoCard = struct {
    // These are row major.
    marks: [5 * 5]bool,
    values: [5 * 5]u8,

    pub fn new(values: [5 * 5]u8) BingoCard {
        return BingoCard{
            .marks = [_]bool{false} ** 25,
            .values = values,
        };
    }

    pub fn mark(self: *BingoCard, valueToMark: u8) bool {
        var didMark = false;
        for (self.values) |value, i| {
            if (value == valueToMark) {
                didMark = !self.marks[i];
                self.marks[i] = true;
            }
        }

        return didMark;
    }

    pub fn hasBingo(self: *BingoCard) bool {
        // Check rows
        {
            var iRow: u8 = 0;
            while (iRow < 5) : (iRow += 1) {
                if (std.mem.eql(bool, self.marks[iRow * 5 .. (iRow * 5 + 5)], &[_]bool{true} ** 5))
                    return true;
            }
        }

        // Check columns
        {
            var iCol: u8 = 0;
            while (iCol < 5) : (iCol += 1) {
                var iRow: u8 = 0;
                var encounteredFalse = false;
                while (iRow < 5) : (iRow += 1) {
                    if (!self.marks[iRow * 5 + iCol]) {
                        encounteredFalse = true;
                        break;
                    }
                }

                if (!encounteredFalse)
                    return true;
            }
        }

        return false;
    }

    fn calculateScore(self: *BingoCard) u32 {
        // Sum all unmarked values.
        var score: u32 = 0;
        for (self.marks) |m, i| {
            if (!m)
                score += self.values[i];
        }

        return score;
    }
};

pub fn run(allocator: std.mem.Allocator) anyerror!void {
    var inputStr = @embedFile("../data/day04_input.txt");
    var reader = std.io.fixedBufferStream(inputStr).reader();

    var numberSequence: []u8 = try parseInputStrNumberSequenceAlloc(allocator, reader);
    defer allocator.free(numberSequence);

    var bingoCardsList = std.ArrayList(BingoCard).init(allocator);
    defer bingoCardsList.deinit();
    while (try parseInputStrBingoCard(reader)) |bingoCard| {
        try bingoCardsList.append(bingoCard);
    }
    log.info("Parsed {d} bingo cards!", .{bingoCardsList.items.len});

    // Find the card that will win first given the number sequence.
    var winningNumber: ?u8 = null;
    var firstWinningBingoCard =
        findFirstWinningBingoCard(bingoCardsList.items, numberSequence, &winningNumber);
    var score = firstWinningBingoCard.?.calculateScore();
    log.info("Part1: ", .{});
    log.info("\tFirst winning bingo card: ", .{});
    log.info("\tscore*winningNumber = {d}*{d} = {d}: ", .{ score, winningNumber, score * winningNumber.? });

    var lastWinningBingoCard =
        try findLastWinningBingoCard(allocator, bingoCardsList.items, numberSequence, &winningNumber);
    score = lastWinningBingoCard.?.calculateScore();
    log.info("Part2: ", .{});
    log.info("\tLast winning bingo card: ", .{});
    log.info("\tscore*winningNumber = {d}*{d} = {d}: ", .{ score, winningNumber, score * winningNumber.? });
}

pub fn parseInputStrNumberSequenceAlloc(allocator: std.mem.Allocator, reader: anytype) ![]u8 {
    var parsedData = std.ArrayList(u8).init(allocator);
    var buffer: [1024]u8 = undefined;
    var lineStr = try reader.readUntilDelimiterOrEof(&buffer, '\n');

    var it = std.mem.split(u8, lineStr.?, ",");
    while (it.next()) |numberStr| {
        try parsedData.append(try std.fmt.parseInt(u8, numberStr, 10));
    }

    return parsedData.toOwnedSlice();
}

pub fn parseInputStrBingoCard(reader: anytype) !?BingoCard {
    var values = [_]u8{0} ** 25;
    var numValuesParsed: usize = 0;

    var buffer: [1024]u8 = undefined;
    var iRow: usize = 0;
    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        if (line.len > 0) {
            var iCol: usize = 0;
            var it = std.mem.tokenize(u8, line, " ");
            while (it.next()) |numberStr| {
                values[iRow * 5 + iCol] = try std.fmt.parseInt(u8, numberStr, 10);
                assert(iCol < 5);
                iCol += 1;
                numValuesParsed += 1;
            }
            assert(iRow < 5);
            iRow += 1;
            if (numValuesParsed == 25)
                break;
        }
    }
    if (numValuesParsed != 25) // Did not manage to parse the a bingoCard... Probably eof
        return null;

    return BingoCard.new(values);
}

pub fn findFirstWinningBingoCard(bingoCards: []BingoCard, numberSequence: []u8, outWinningNumber: *?u8) ?*BingoCard {
    for (numberSequence) |n| {
        for (bingoCards) |_, i| {
            var card: *BingoCard = &bingoCards[i];
            if (card.mark(n)) {
                if (card.hasBingo()) {
                    outWinningNumber.* = n;
                    return card;
                }
            }
        }
    }

    return null;
}

pub fn findLastWinningBingoCard(allocator: std.mem.Allocator, bingoCards: []BingoCard, numberSequence: []u8, outWinningNumber: *?u8) !?*BingoCard {
    var lastWinningBingoCard: ?*BingoCard = null;

    var winStatus: []bool = try allocator.alloc(bool, bingoCards.len);
    defer allocator.free(winStatus);

    var numCardsWithBingo: usize = 0;
    outer: for (numberSequence) |n| {
        for (bingoCards) |_, i| {
            var card: *BingoCard = &bingoCards[i];
            if (card.mark(n) and !winStatus[i]) {
                if (card.hasBingo()) {
                    outWinningNumber.* = n;
                    lastWinningBingoCard = card;
                    winStatus[i] = true;
                    numCardsWithBingo += 1;
                }
            }
            if (numCardsWithBingo == bingoCards.len) break :outer;
        }
    }

    return lastWinningBingoCard;
}

test "parse number sequence" {
    const example = "1,2,3";
    var reader = std.io.fixedBufferStream(example).reader();

    var numberSequence = try parseInputStrNumberSequenceAlloc(testing.allocator, reader);
    defer testing.allocator.free(numberSequence);

    try testing.expect(std.mem.eql(u8, numberSequence, &[_]u8{ 1, 2, 3 }));
}

test "parse bingo card" {
    const example =
        \\
        \\14 21 17 24  4
        \\10 16 15  9 19
        \\18  8 23 26 20
        \\22 11 13  6  5
        \\ 2  0 12  3  7
    ;
    var reader = std.io.fixedBufferStream(example).reader();

    var bingoCard = (try parseInputStrBingoCard(reader)).?;
    try testing.expect(std.mem.eql(u8, &bingoCard.values, &[25]u8{ 14, 21, 17, 24, 4, 10, 16, 15, 9, 19, 18, 8, 23, 26, 20, 22, 11, 13, 6, 5, 2, 0, 12, 3, 7 }));

    var nextBingoCard = (try parseInputStrBingoCard(reader));
    try testing.expect(nextBingoCard == null);

    var bingoCardRow = bingoCard;
    try testing.expectEqual(bingoCardRow.hasBingo(), false);
    for ([_]u8{ 14, 21, 17, 24, 4 }) |v| {
        _ = bingoCardRow.mark(v);
    }
    try testing.expectEqual(bingoCardRow.hasBingo(), true);

    var bingoCardCol = bingoCard;
    try testing.expectEqual(bingoCardCol.hasBingo(), false);
    for ([_]u8{ 14, 10, 18, 22, 2 }) |v| {
        _ = bingoCardCol.mark(v);
    }
    try testing.expectEqual(bingoCardCol.hasBingo(), true);

    var bingoCardScore = bingoCard;
    try testing.expectEqual(bingoCardScore.hasBingo(), false);
    for ([_]u8{ 7, 4, 9, 5, 11, 17, 23, 2, 0, 14, 21, 24 }) |v| {
        _ = bingoCardScore.mark(v);
    }
    try testing.expectEqual(bingoCardScore.hasBingo(), true);
    try testing.expectEqual(bingoCardScore.calculateScore(), 188);
}

test "part 1 and part 2" {
    const example =
        \\7,4,9,5,11,17,23,2,0,14,21,24,10,16,13,6,15,25,12,22,18,20,8,19,3,26,1
        \\
        \\22 13 17 11  0
        \\ 8  2 23  4 24
        \\21  9 14 16  7
        \\ 6 10  3 18  5
        \\ 1 12 20 15 19
        \\
        \\ 3 15  0  2 22
        \\ 9 18 13 17  5
        \\19  8  7 25 23
        \\20 11 10 24  4
        \\14 21 16 12  6
        \\
        \\14 21 17 24  4
        \\10 16 15  9 19
        \\18  8 23 26 20
        \\22 11 13  6  5
        \\ 2  0 12  3  7
    ;

    var reader = std.io.fixedBufferStream(example).reader();

    var numberSequence: []u8 = try parseInputStrNumberSequenceAlloc(testing.allocator, reader);
    defer testing.allocator.free(numberSequence);

    var bingoCardsList = std.ArrayList(BingoCard).init(testing.allocator);
    defer bingoCardsList.deinit();
    while (try parseInputStrBingoCard(reader)) |bingoCard| {
        try bingoCardsList.append(bingoCard);
    }
    log.info("Parsed {d} bingo cards!", .{bingoCardsList.items.len});

    // Find the card that will win first given the number sequence.
    var winningNumber: ?u8 = null;
    var firstWinningBingoCard =
        findFirstWinningBingoCard(bingoCardsList.items, numberSequence, &winningNumber);

    try testing.expectEqual(firstWinningBingoCard.?.calculateScore(), 188);
    try testing.expectEqual(winningNumber, 24);

    var lastWinningBingoCard =
        try findLastWinningBingoCard(testing.allocator, bingoCardsList.items, numberSequence, &winningNumber);

    try testing.expectEqual(lastWinningBingoCard.?.calculateScore(), 148);
    try testing.expectEqual(winningNumber.?, 13);
}
