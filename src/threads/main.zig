const std = @import("std");
const stdout = std.io.getStdOut().writer();

fn someWork(id: u8) void {
    std.debug.print("Starting some work on thread {d}\n", .{id});
    std.time.sleep(2 * std.time.ns_per_s);
    std.debug.print("Finishing some work on thread {d}\n", .{id});
}

var counter: usize = 0;

fn globalIncrement(mutex: *std.Thread.Mutex) void {
    for (0..10000) |_| {
        mutex.lock();
        counter += 1;
        mutex.unlock();
    }
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

    // try pool.spawn(someWork, .{1});
    // try pool.spawn(someWork, .{2});

    var wg: std.Thread.WaitGroup = .{};
    var mutex: std.Thread.Mutex = .{};

    pool.spawnWg(&wg, globalIncrement, .{&mutex});
    pool.spawnWg(&wg, globalIncrement, .{&mutex});

    wg.wait();

    std.debug.print("counter is {d}", .{counter});
}
