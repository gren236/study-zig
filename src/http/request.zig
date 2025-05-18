const std = @import("std");
const Connection = std.net.Server.Connection;
const Map = std.static_string_map.StaticStringMap;

pub const Method = enum {
    GET,

    pub fn init(text: []const u8) !Method {
        return MethodMap.get(text).?;
    }

    pub fn isSupported(m: []const u8) bool {
        MethodMap.get(m) catch {
            return false;
        };

        return true;
    }
};

const MethodMap = Map(Method).initComptime(.{.{ "GET", Method.GET }});

const Request = struct {
    method: Method,
    version: []const u8,
    uri: []const u8,

    pub fn init(method: Method, version: []const u8, uri: []const u8) Request {
        return Request{
            .method = method,
            .version = version,
            .uri = uri,
        };
    }
};

pub fn readRequest(conn: Connection, buffer: []u8) !void {
    const reader = conn.stream.reader();
    _ = try reader.read(buffer);
}

pub fn parseRequest(text: []const u8) Request {
    const lineIndex = std.mem.indexOfScalar(u8, text, '\n') orelse text.len;
    var iterator = std.mem.splitScalar(u8, text[0..lineIndex], ' ');

    const method = try Method.init(iterator.next().?);
    const uri = iterator.next().?;
    const version = iterator.next().?;

    return Request.init(method, version, uri);
}
