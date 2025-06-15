const std = @import("std");

const defaultStackLength = 10;

pub const Error = error{NoMoreElements};

pub fn Stack(T: type) type {
    return struct {
        items: []T,
        length: usize,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) !Stack(T) {
            return .{ .allocator = allocator, .length = 0, .items = try allocator.alloc(u32, defaultStackLength) };
        }

        pub fn deinit(self: *Stack(T)) void {
            self.allocator.free(self.items);
        }

        pub fn push(self: *Stack(T), val: T) !void {
            try self.realloc();

            self.items[self.length] = val;
            self.length += 1;
        }

        pub fn pop(self: *Stack(T)) !T {
            if (self.length == 0) {
                return Error.NoMoreElements;
            }

            self.length -= 1;

            return self.items[self.length];
        }

        fn realloc(self: *Stack(T)) !void {
            if (self.length < self.items.len) {
                return;
            }

            const newSize = self.items.len * 2;
            self.items = try self.allocator.realloc(self.items, newSize);
        }
    };
}

const expect = std.testing.expect;

test "stack operations" {
    const allocator = std.testing.allocator;

    var testStack = try Stack(u32).init(allocator);
    defer testStack.deinit();

    try testStack.push(42);
    try expect(testStack.length == 1);
    try expect(try testStack.pop() == 42);
    try expect(testStack.length == 0);

    // Add more to provoke reallocation
    for (1..13) |i| {
        try testStack.push(@as(u32, @intCast(i)));
    }

    try expect(testStack.length == 12);
    try expect(testStack.items.len == 20);
}
