//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

const std = @import("std");
const base64 = @import("base64.zig");

pub fn main() !void {
    var memory_buffer: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&memory_buffer);
    const allocator = fba.allocator();

    const text = "Testing some more stuff";
    const etext = "VGVzdGluZyBzb21lIG1vcmUgc3R1ZmY=";
    const b64 = base64.init();
    const encoded_text = try b64.encode(allocator, text);
    const decoded_text = try b64.decode(allocator, etext);

    std.debug.print("Encoded text: {s}\n", .{encoded_text});
    std.debug.print("Decoded text: {s}\n", .{decoded_text});
}
