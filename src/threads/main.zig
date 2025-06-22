const std = @import("std");
const stdout = std.io.getStdOut().writer();

fn someWork(id: u8) void {
    std.debug.print("Starting some work on thread {d}\n", .{id});
    std.time.sleep(2 * std.time.ns_per_s);
    std.debug.print("Finishing some work on thread {d}\n", .{id});
}

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    const allocator = gpa.allocator();
    var pool: std.Thread.Pool = undefined;
    try pool.init(.{
        .allocator = allocator,
        .n_jobs = 4,
    });
    defer pool.deinit();

    try pool.spawn(someWork, .{1});
    try pool.spawn(someWork, .{2});
}
