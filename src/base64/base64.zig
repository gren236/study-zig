const std = @import("std");

const Base64 = @This();

table: *const [64]u8,

pub fn init() Base64 {
    const upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    const lower = "abcdefghijklmnopqrstuvwxyz";
    const numbers_symb = "0123456789+/";

    return Base64{
        .table = upper ++ lower ++ numbers_symb,
    };
}

fn charAt(self: Base64, index: usize) u8 {
    return self.table[index];
}

fn charIndex(self: Base64, char: u8) u8 {
    if (char == '=') return 64;

    return @truncate(std.mem.indexOf(u8, self.table, &[1]u8{char}).?);
}

fn encodeLength(input: []const u8) !usize {
    if (input.len < 3) {
        return 4;
    }

    const result: usize = try std.math.divCeil(usize, input.len, 3);
    return result * 4;
}

fn decodeLength(input: []const u8) !usize {
    if (input.len < 4) {
        return 3;
    }

    const groups = try std.math.divFloor(usize, input.len, 4);
    var multipleGroups = groups * 3;
    
    for (0..input.len) |i| {
        if (input[input.len - 1 - i] == '=') {
            multipleGroups -= 1;
        } else {
            break;
        }
    }
    
    return multipleGroups;
}

pub fn encode(self: Base64, allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    if (input.len == 0) {
        return "";
    }

    const lenOut = try encodeLength(input);
    var out = try allocator.alloc(u8, lenOut);
    var buf = [3]u8{ 0, 0, 0 };
    var count: u8 = 0;
    var iout: u64 = 0;

    for (input, 0..) |_, i| {
        buf[count] = input[i];
        count += 1;

        if (count == 3) {
            out[iout] = self.charAt(buf[0] >> 2);
            out[iout + 1] = self.charAt(((buf[0] & 0x03) << 4) | (buf[1] >> 4));
            out[iout + 2] = self.charAt(((buf[1] & 0x0f) << 2) | (buf[2] >> 6));
            out[iout + 3] = self.charAt(buf[2] & 0x3f);

            iout += 4;
            count = 0;
        }
    }

    if (count == 1) {
        out[iout] = self.charAt(buf[0] >> 2);
        out[iout + 1] = self.charAt((buf[0] & 0x03) << 4);
        out[iout + 2] = '=';
        out[iout + 3] = '=';
    }

    if (count == 2) {
        out[iout] = self.charAt(buf[0] >> 2);
        out[iout + 1] = self.charAt(((buf[0] & 0x03) << 4) | (buf[1] >> 4));
        out[iout + 2] = self.charAt((buf[1] & 0x0f) << 2);
        out[iout + 3] = '=';

        iout += 4;
    }

    return out;
}

pub fn decode(self: Base64, allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    if (input.len == 0) {
        return "";
    }

    const lenOut = try decodeLength(input);
    var output = try allocator.alloc(u8, lenOut);
    var count: u8 = 0;
    var iout: u64 = 0;
    var buf = [4]u8{ 0, 0, 0, 0 };

    for (0..input.len) |i| {
        buf[count] = self.charIndex(input[i]);
        count += 1;

        if (count == 4) {
            output[iout] = (buf[0] << 2) | (buf[1] >> 4);
            if (buf[2] != 64) {
                output[iout + 1] = (buf[1] << 4) | (buf[2] >> 2);
            }
            if (buf[3] != 64) {
                output[iout + 2] = (buf[2] << 6) | buf[3];
            }

            iout += 3;
            count = 0;
        }
    }

    return output;
}

const testing = std.testing;
test "correct encode/decode length" {
    const testInputEncode = "Hi";
    const testInputEncodeResult = try encodeLength(testInputEncode);

    try testing.expect(testInputEncodeResult == 4);

    const testInputDecode = "SGk=";
    const testInputDecodeResult = try decodeLength(testInputDecode);

    try testing.expect(testInputDecodeResult == 2);
}

test "correct encoding" {
    const b64 = Base64.init();
    const testInput = "Hello world!!";
    const testInputEncoded = try b64.encode(testing.allocator, testInput);
    defer testing.allocator.free(testInputEncoded);

    try testing.expectEqualStrings("SGVsbG8gd29ybGQhIQ==", testInputEncoded);
}

test "correct decoding" {
    const b64 = Base64.init();
    const testInput = "SGVsbG8gd29ybGQhIQ==";
    const testInputEncoded = try b64.decode(testing.allocator, testInput);
    defer testing.allocator.free(testInputEncoded);

    try testing.expectEqualStrings("Hello world!!", testInputEncoded);
}
