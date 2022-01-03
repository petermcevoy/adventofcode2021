const std = @import("std");
const testing = std.testing;
const stdout = std.io.getStdOut().writer();

pub fn run() anyerror!void {
    var input_str = @embedFile("../data/day16_input.txt");
    var buffer: [8000]u1 = undefined;
    var bits = hexStrToBitBuffer(input_str, &buffer);

    var it = PacketStreamIterator.new(bits);
    var version_sum: usize = 0;
    while (it.next()) |packet| version_sum += packet.version;
    try stdout.print("Part 1: {d}\n", .{version_sum});

    var value = processBITS(bits);
    try stdout.print("Part 2: {d}\n", .{value});
}

pub fn hexStrToBitBuffer(str: []const u8, bit_buffer: []u1) []const u1 {
    var i_bit: usize = 0;
    for (str) |hex_char| {
        if (hex_char == 10) continue;
        var hex: u4 = std.fmt.parseInt(u4, &[1]u8{hex_char}, 16) catch {
            std.debug.print("Unable to parse char as u4: {c}({d})\n", .{ hex_char, hex_char });
            unreachable;
        };

        bit_buffer[i_bit + 3] = @intCast(u1, (hex & 0b0001) >> 0);
        bit_buffer[i_bit + 2] = @intCast(u1, (hex & 0b0010) >> 1);
        bit_buffer[i_bit + 1] = @intCast(u1, (hex & 0b0100) >> 2);
        bit_buffer[i_bit + 0] = @intCast(u1, (hex & 0b1000) >> 3);
        i_bit += 4;
    }

    return bit_buffer[0..i_bit];
}

const PacketType = enum(u3) {
    op_sum = 0,
    op_product = 1,
    op_min = 2,
    op_max = 3,

    literal = 4,

    // The following ops always have two sub-packets
    op_greater_than = 5,
    op_less_than = 6,
    op_equal_to = 7,
};

const SubPacketLengthType = enum(u1) { num_sub_packets = 1, sub_packets_bitsize = 0 };
const SubPacketLength = union(SubPacketLengthType) {
    num_sub_packets: u11,
    sub_packets_bitsize: u15,
};

const Packet = struct {
    version: u3,
    type_id: PacketType,
    sub_packets_length: SubPacketLength,
    value: u64, // only for .literal
};

const PacketStreamIterator = struct {
    bit_buffer: []const u1,
    num_bits_read: usize = 0,
    num_packets_read: usize = 0,

    pub fn new(bit_buffer: []const u1) @This() {
        return @This(){ .bit_buffer = bit_buffer };
    }

    pub fn next(self: *@This()) ?Packet {
        // Check if we are end of stream
        if (self.bit_buffer.len < 3) return null;
        if (self.bit_buffer.len < 8 and bitsToInt(u3, self.bit_buffer[0..3]) == 0) return null;

        var packet_size: usize = 0;
        var packet = Packet{
            .version = bitsToInt(u3, self.bit_buffer[0..3]),
            .type_id = @intToEnum(PacketType, bitsToInt(u3, self.bit_buffer[3..6])),
            .sub_packets_length = undefined,
            .value = undefined,
        };
        packet_size += 3 + 3; // version and type id

        switch (packet.type_id) {
            .literal => packet_size += variableLengthBitsToInt(self.bit_buffer[6..], &packet.value),
            else => {
                // Operator packet
                var length_type = @intToEnum(SubPacketLengthType, bitsToInt(u1, self.bit_buffer[6..7]));
                packet_size += 1;
                switch (length_type) {
                    .num_sub_packets => {
                        packet.sub_packets_length = .{ .num_sub_packets = bitsToInt(u11, self.bit_buffer[7 .. 7 + 11]) };
                        packet_size += 11;
                    },
                    .sub_packets_bitsize => {
                        packet.sub_packets_length = .{ .sub_packets_bitsize = bitsToInt(u15, self.bit_buffer[7 .. 7 + 15]) };
                        packet_size += 15;
                    },
                }
            },
        }

        self.num_bits_read += packet_size;
        self.num_packets_read += 1;
        self.bit_buffer = self.bit_buffer[packet_size..];

        return packet;
    }
};

pub fn processOperatorPacketRecursive(op_packet: Packet, it: *PacketStreamIterator) u64 {
    if (op_packet.type_id == .literal) return op_packet.value;

    var start_num_bit_read = it.num_bits_read;
    var sub_packet_values = std.BoundedArray(u64, 64).init(0) catch unreachable;

    // Parse the sub packets...
    var continue_reading_subpackets: bool = true;
    while (continue_reading_subpackets) {
        var packet = it.next().?;
        switch (packet.type_id) {
            .literal => sub_packet_values.append(packet.value) catch unreachable,
            else => {
                var value = processOperatorPacketRecursive(packet, it);
                sub_packet_values.append(value) catch unreachable;
            },
        }

        switch (op_packet.sub_packets_length) {
            .sub_packets_bitsize => |size| {
                if (it.num_bits_read == start_num_bit_read + size) {
                    continue_reading_subpackets = false;
                } else if (it.num_bits_read > start_num_bit_read + size) unreachable;
            },
            .num_sub_packets => |num| {
                if (sub_packet_values.len == num) {
                    continue_reading_subpackets = false;
                } else if (sub_packet_values.len > num) unreachable;
            },
        }
    }

    var value: u64 = 0;
    switch (op_packet.type_id) {
        .op_sum => {
            value = 0;
            while (sub_packet_values.len > 0) value += sub_packet_values.pop();
        },
        .op_product => {
            value = 1;
            while (sub_packet_values.len > 0) value *= sub_packet_values.pop();
        },
        .op_min => {
            value = sub_packet_values.pop();
            while (sub_packet_values.len > 0) value = @minimum(value, sub_packet_values.pop());
        },
        .op_max => {
            value = sub_packet_values.pop();
            while (sub_packet_values.len > 0) value = @maximum(value, sub_packet_values.pop());
        },
        .op_less_than => {
            std.debug.assert(sub_packet_values.len == 2);
            value = @boolToInt(sub_packet_values.pop() > sub_packet_values.pop());
        },
        .op_greater_than => {
            std.debug.assert(sub_packet_values.len == 2);
            value = @boolToInt(sub_packet_values.pop() < sub_packet_values.pop());
        },
        .op_equal_to => {
            std.debug.assert(sub_packet_values.len == 2);
            value = @boolToInt(sub_packet_values.pop() == sub_packet_values.pop());
        },
        else => {
            std.debug.print("Missing case for {s}\n", .{op_packet.type_id});
            unreachable;
        },
    }

    return value;
}

pub fn processBITS(bits: []const u1) u64 {
    var it = PacketStreamIterator.new(bits);
    var first_packet = it.next().?;
    var value = processOperatorPacketRecursive(first_packet, &it);
    return value;
}

pub fn bitsToInt(comptime T: type, bits: []const u1) T {
    var value: T = 0;
    var i_bit: usize = 0;
    while (i_bit < @bitSizeOf(T)) : (i_bit += 1) value |= @intCast(T, bits[i_bit]) <<| i_bit;
    return @bitReverse(T, value);
}

test "bitsToInt" {
    var val = bitsToInt(u3, &[4]u1{ 0, 0, 1, 0 });
    try testing.expectEqual(val, 1);
    val = bitsToInt(u3, &[4]u1{ 0, 1, 1, 0 });
    try testing.expectEqual(val, 3);
}

pub fn variableLengthBitsToInt(bits: []const u1, value: *u64) usize {
    // Read in groups of 5
    value.* = 0;

    var i_group: usize = 0;
    var last_group: bool = false;
    while (!last_group) {
        if (bits[i_group * 5] == 0) last_group = true;

        value.* |= @intCast(u64, bits[i_group * 5 + 1]) <<| (i_group * 4 + 0);
        value.* |= @intCast(u64, bits[i_group * 5 + 2]) <<| (i_group * 4 + 1);
        value.* |= @intCast(u64, bits[i_group * 5 + 3]) <<| (i_group * 4 + 2);
        value.* |= @intCast(u64, bits[i_group * 5 + 4]) <<| (i_group * 4 + 3);

        i_group += 1;
    }

    value.* = @bitReverse(u64, value.*) >> @intCast(u6, 64 - i_group * 4);

    return i_group * 5;
}

test "variableLengthBitsToInt" {
    var val: u64 = undefined;
    var bits_read = variableLengthBitsToInt(&[18]u1{ 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0 }, &val);
    try testing.expectEqual(val, 2021);
    try testing.expectEqual(bits_read, 15);

    bits_read = variableLengthBitsToInt(&[5]u1{ 0, 1, 0, 1, 0 }, &val);
    try testing.expectEqual(val, 10);
    try testing.expectEqual(bits_read, 5);
}

test "packet parsing" {
    var buffer: [100]u1 = undefined;
    var bits = hexStrToBitBuffer("38006F45291200", &buffer);
    try testing.expectEqualSlices(u1, bits, &[_]u1{ 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0 });

    var it = PacketStreamIterator.new(bits);
    var packet = it.next().?;
    try testing.expectEqual(packet.version, 1);
    try testing.expectEqual(packet.type_id, @intToEnum(PacketType, 6));
    try testing.expectEqual(packet.sub_packets_length, .{ .sub_packets_bitsize = 27 });

    packet = it.next().?;
    try testing.expectEqual(packet.type_id, @intToEnum(PacketType, 4));
    try testing.expectEqual(packet.value, 10);

    packet = it.next().?;
    try testing.expectEqual(packet.type_id, @intToEnum(PacketType, 4));
    try testing.expectEqual(packet.value, 20);

    try testing.expectEqual(it.next(), null);
}

test "part 1" {
    var buffer: [1000]u1 = undefined;

    var bits = hexStrToBitBuffer("8A004A801A8002F478", &buffer);
    var it = PacketStreamIterator.new(bits);
    var version_sum: usize = 0;
    while (it.next()) |packet| version_sum += packet.version;
    try testing.expectEqual(version_sum, 16);

    bits = hexStrToBitBuffer("620080001611562C8802118E34", &buffer);
    it = PacketStreamIterator.new(bits);
    version_sum = 0;
    while (it.next()) |packet| version_sum += packet.version;
    try testing.expectEqual(version_sum, 12);

    bits = hexStrToBitBuffer("C0015000016115A2E0802F182340", &buffer);
    it = PacketStreamIterator.new(bits);
    version_sum = 0;
    while (it.next()) |packet| version_sum += packet.version;
    try testing.expectEqual(version_sum, 23);

    bits = hexStrToBitBuffer("A0016C880162017C3686B18A3D4780", &buffer);
    it = PacketStreamIterator.new(bits);
    version_sum = 0;
    while (it.next()) |packet| version_sum += packet.version;
    try testing.expectEqual(version_sum, 31);
}

test "part 2" {
    var buffer: [1000]u1 = undefined;
    var bits: []const u1 = undefined;

    // C200B40A82 finds the sum of 1 and 2, resulting in the value 3
    bits = hexStrToBitBuffer("C200B40A82", &buffer);
    try testing.expectEqual(processBITS(bits), 3);

    //04005AC33890 finds the product of 6 and 9, resulting in the value 54
    bits = hexStrToBitBuffer("04005AC33890", &buffer);
    try testing.expectEqual(processBITS(bits), 54);

    //880086C3E88112 finds the minimum of 7, 8, and 9, resulting in the value 7
    bits = hexStrToBitBuffer("880086C3E88112", &buffer);
    try testing.expectEqual(processBITS(bits), 7);

    // CE00C43D881120 finds the maximum of 7, 8, and 9, resulting in the value 9.
    bits = hexStrToBitBuffer("CE00C43D881120", &buffer);
    try testing.expectEqual(processBITS(bits), 9);

    //D8005AC2A8F0 produces 1, because 5 is less than 15
    bits = hexStrToBitBuffer("D8005AC2A8F0", &buffer);
    try testing.expectEqual(processBITS(bits), 1);

    //F600BC2D8F produces 0, because 5 is not greater than 15.
    bits = hexStrToBitBuffer("F600BC2D8F", &buffer);
    try testing.expectEqual(processBITS(bits), 0);

    //9C005AC2F8F0 produces 0, because 5 is not equal to 15.
    bits = hexStrToBitBuffer("9C005AC2F8F0", &buffer);
    try testing.expectEqual(processBITS(bits), 0);

    //9C0141080250320F1802104A08 produces 1, because 1 + 3 = 2 * 2.
    bits = hexStrToBitBuffer("9C0141080250320F1802104A08", &buffer);
    try testing.expectEqual(processBITS(bits), 1);
}
