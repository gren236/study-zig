const std = @import("std");
const stdin = std.io.getStdIn();
const stdout = std.io.getStdOut();
const cwd = std.fs.cwd();

fn testReadName() !void {
    try stdout.writeAll("Hello! Type your name: \n");
    var buffer: [20]u8 = undefined;
    const name: []u8 = buffer[0..];
    @memset(name, 0);

    _ = try stdin.reader().readUntilDelimiterOrEof(name, '\n');

    try stdout.writer().print("Your name is: {s}", .{name});
}

fn testReadFile() !void {
    var file = try std.fs.cwd().openFile("./lorem.txt", .{});
    defer file.close();

    var bufferedReader = std.io.bufferedReader(file.reader());
    var reader = bufferedReader.reader();
    var buffer: [1000]u8 = undefined;
    @memset(buffer[0..], 0);

    _ = try reader.readUntilDelimiterOrEof(buffer[0..], '\n');
    try stdout.writer().print("{s}", .{buffer});
}

pub fn main() !void {
    // testReadName();
    // testReadFile();

    var file = try cwd.createFile("./test.txt", .{});
    defer file.close();

    try file.writer().writeAll("Hello there!\n");
}
