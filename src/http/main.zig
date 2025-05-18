const std = @import("std");
const SocketConf = @import("config.zig");
const Request = @import("request.zig");
const Method = Request.Method;
const Response = @import("response.zig");
const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    const socket = try SocketConf.Socket.init();
    try stdout.print("Server Address: {any}\n", .{socket.address});

    var server = try socket.address.listen(.{});
    const connection = try server.accept();

    var buffer: [1000]u8 = undefined;
    for (0..buffer.len) |i| {
        buffer[i] = 0;
    }

    try Request.readRequest(connection, buffer[0..buffer.len]);
    try stdout.print("{s}\n", .{buffer});

    const request = Request.parseRequest(buffer[0..buffer.len]);
    try stdout.print("{any}\n", .{request});

    if (request.method == Method.GET) {
        if (std.mem.eql(u8, request.uri, "/")) {
            try Response.send200(connection);
        } else {
            try Response.send400(connection);
        }
    }
}
