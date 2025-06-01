const std = @import("std");

fn testArrayList() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const allocator = gpa.allocator();

    var buffer = try std.ArrayList(u8).initCapacity(allocator, 100);
    defer buffer.deinit();

    try buffer.append('f');
    try buffer.append('o');
    try buffer.append('o');

    std.debug.print("{s}\n", .{buffer.items});

    try buffer.appendSlice(" bar\n");

    std.debug.print("{s}", .{buffer.items});

    const newline = buffer.pop() orelse undefined;
    std.debug.print("{u}", .{newline});

    try buffer.insertSlice(3, " baz");

    std.debug.print("{s}\n\n", .{buffer.items});
}

fn testHashMap() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const allocator = gpa.allocator();

    var hashTable = std.AutoHashMap(u32, []const u8).init(allocator);
    defer hashTable.deinit();

    try hashTable.put(0, "hello");
    try hashTable.put(1, "world");
    try hashTable.put(3, "foo");

    printHashMap(hashTable);

    std.debug.print("{s}\n\n", .{hashTable.get(1).?});

    // string hash map
    const allocator2 = gpa.allocator();
    var stringHashTable = std.StringHashMap([]const u8).init(allocator2);
    defer stringHashTable.deinit();

    try stringHashTable.put("hello", "world");
    try stringHashTable.put("foo", "bar");

    printHashMap(stringHashTable);
}

fn printHashMap(map: anytype) void {
    var iter = map.iterator();
    while (iter.next()) |val| {
        const KeyType = @TypeOf(val.key_ptr.*);
        comptime var arg = "d";
        if (KeyType == []const u8) {
            arg = "s";
        }

        std.debug.print("{" ++ arg ++ "}: {s}\n", .{ val.key_ptr.*, val.value_ptr.* });
    }
}

pub fn main() !void {
    try testArrayList();
    try testHashMap();
}
