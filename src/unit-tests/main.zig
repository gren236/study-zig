const expect = std.testing.expect;
const expectError = std.testing.expectError;
const Allocator = std.mem.Allocator;

const std = @import("std");
test "testing simple sum" {
    const a = 2;
    const b = 2;

    try expect((a + b) == 4);
}

fn someMemoryLeak(allocator: Allocator) !void {
    const buffer = try allocator.alloc(u32, 10);
    _ = buffer;
    // Return without freeing the memory
}

fn someDoubleFree(allocator: Allocator) !void {
    const buffer = try allocator.alloc(u32, 10);

    allocator.free(buffer);
    allocator.free(buffer);
}

// test "memory leak" {
//     const allocator = std.testing.allocator;
//     try someMemoryLeak(allocator);
// }

// test "double freeing" {
//     const allocator = std.testing.allocator;
//     try someDoubleFree(allocator);
// }

fn allocError(allocator: Allocator) !void {
    var ibuffer = try allocator.alloc(u8, 100);
    defer allocator.free(ibuffer);
    ibuffer[0] = 2;
}

test "testing error" {
    var buffer: [10]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    try expectError(error.OutOfMemory, allocError(allocator));
}
