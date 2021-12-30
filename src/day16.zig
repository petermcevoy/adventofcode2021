const std = @import("std");
const testing = std.testing;
const stdout = std.io.getStdOut().writer();

pub fn run() anyerror!void {
    var input_str = @embedFile("../data/day16_input.txt");
    var buffer: [8000]u1 = undefined;
    var bits = hexStrBuffer2BitBuffer(input_str, &buffer);

    var it = PacketStreamIterator.new(bits);
    var version_sum: usize = 0;
    while (it.next()) |packet| version_sum += packet.version;
    try stdout.print("Part 1: {d}\n", .{version_sum});
}

pub fn hexStrBuffer2BitBuffer(str: []const u8, bit_buffer: []u1) []const u1 {
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

const Packet = struct {
    version: u3,
    type_id: u3,

    // For operator packets.
    // 0 = next 15 bits represent the total length in bits of the sub-packet
    // 1 = next 11 bits represent the number of sub-packets contained in this packet
    length_type_id: u1,
    sub_packets_size: u15, // if length type is 0
    num_sub_packets: u11, // if length type is 1

    value: u64,
};

pub fn readBits(comptime T: type, bits: []const u1) T {
    var value: T = 0;
    var i_bit: usize = 0;
    while (i_bit < @bitSizeOf(T)) : (i_bit += 1) {
        value |= @intCast(T, bits[i_bit]) <<| i_bit;
    }

    return @bitReverse(T, value);
}

test "readBits" {
    var val = readBits(u3, &[4]u1{ 0, 0, 1, 0 });
    try testing.expectEqual(val, 1);
    val = readBits(u3, &[4]u1{ 0, 1, 1, 0 });
    try testing.expectEqual(val, 3);
}

pub fn readBitsVariableLength(bits: []const u1, value: *u64) usize {
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
test "readBitsVariableLength" {
    var val: u64 = undefined;
    var bits_read = readBitsVariableLength(&[18]u1{ 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0 }, &val);
    try testing.expectEqual(val, 2021);
    try testing.expectEqual(bits_read, 15);

    bits_read = readBitsVariableLength(&[5]u1{ 0, 1, 0, 1, 0 }, &val);
    try testing.expectEqual(val, 10);
    try testing.expectEqual(bits_read, 5);
}

const PacketStreamIterator = struct {
    bit_buffer: []const u1,
    //sub_packet_size_stack: std.BoundedArray(SubPacketLength, iterator_stack_size),
    //num_packets_read: usize = 0,

    //const iterator_stack_size = 32;
    //const SubPacketLengthType = enum { num_sub_packets, sub_packets_size };
    //const SubPacketLength = union(SubPacketLengthType) {
    //    num_sub_packets: usize,
    //    sub_packets_size: usize,
    //};

    pub fn new(bit_buffer: []const u1) @This() {
        return @This(){
            .bit_buffer = bit_buffer,
            //.sub_packet_size_stack = std.BoundedArray(SubPacketLength, iterator_stack_size).init(1) catch unreachable,
        };
    }

    pub fn next(self: *@This()) ?Packet {
        //if (self.num_packets_read > 0) {
        //    // Deal with packet size stack..
        //}

        // Check if we are end of stream
        if (self.bit_buffer.len < 3) return null;
        if (self.bit_buffer.len < 8 and readBits(u3, self.bit_buffer[0..3]) == 0) return null;

        var packet_size: usize = 0;
        var packet = Packet{
            .version = readBits(u3, self.bit_buffer[0..3]),
            .type_id = readBits(u3, self.bit_buffer[3..6]),
            .length_type_id = undefined,
            .sub_packets_size = undefined,
            .num_sub_packets = undefined,
            .value = undefined,
        };
        packet_size += 3 + 3;

        if (packet.type_id == 4) { // literal value
            packet_size += readBitsVariableLength(self.bit_buffer[6..], &packet.value);
        } else { // Operator packet
            packet.length_type_id = readBits(u1, self.bit_buffer[6..7]);
            packet_size += 1;
            if (packet.length_type_id == 0) {
                packet.sub_packets_size = readBits(u15, self.bit_buffer[7 .. 7 + 15]);
                packet_size += 15;
                //self.sub_packet_size_stack.append(.{ .sub_packets_size = packet.sub_packets_size }) catch unreachable;
            } else {
                packet.num_sub_packets = readBits(u11, self.bit_buffer[7 .. 7 + 11]);
                packet_size += 11;
                //self.sub_packet_size_stack.append(.{ .num_sub_packets = packet.num_sub_packets }) catch unreachable;
            }
        }

        self.bit_buffer = self.bit_buffer[packet_size..];

        return packet;
    }
};

test "packet parsing" {
    var buffer: [100]u1 = undefined;
    var bits = hexStrBuffer2BitBuffer("38006F45291200", &buffer);
    try testing.expectEqualSlices(u1, bits, &[_]u1{ 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0 });

    var it = PacketStreamIterator.new(bits);
    var packet = it.next().?;
    try testing.expectEqual(packet.version, 1);
    try testing.expectEqual(packet.type_id, 6);
    try testing.expectEqual(packet.length_type_id, 0);
    try testing.expectEqual(packet.sub_packets_size, 27);

    packet = it.next().?;
    try testing.expectEqual(packet.type_id, 4);
    try testing.expectEqual(packet.value, 10);

    packet = it.next().?;
    try testing.expectEqual(packet.type_id, 4);
    try testing.expectEqual(packet.value, 20);

    try testing.expectEqual(it.next(), null);
}

test "part 1" {
    var buffer: [1000]u1 = undefined;

    var bits = hexStrBuffer2BitBuffer("8A004A801A8002F478", &buffer);
    var it = PacketStreamIterator.new(bits);
    var version_sum: usize = 0;
    while (it.next()) |packet| version_sum += packet.version;
    try testing.expectEqual(version_sum, 16);

    bits = hexStrBuffer2BitBuffer("620080001611562C8802118E34", &buffer);
    it = PacketStreamIterator.new(bits);
    version_sum = 0;
    while (it.next()) |packet| version_sum += packet.version;
    try testing.expectEqual(version_sum, 12);

    bits = hexStrBuffer2BitBuffer("C0015000016115A2E0802F182340", &buffer);
    it = PacketStreamIterator.new(bits);
    version_sum = 0;
    while (it.next()) |packet| version_sum += packet.version;
    try testing.expectEqual(version_sum, 23);

    bits = hexStrBuffer2BitBuffer("A0016C880162017C3686B18A3D4780", &buffer);
    it = PacketStreamIterator.new(bits);
    version_sum = 0;
    while (it.next()) |packet| version_sum += packet.version;
    try testing.expectEqual(version_sum, 31);
}

test "part 2" {
    // C200B40A82 finds the sum of 1 and 2, resulting in the value 3
    // CE00C43D881120 finds the maximum of 7, 8, and 9, resulting in the value 9.
}
