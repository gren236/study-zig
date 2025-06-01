const std = @import("std");
const expect = std.testing.expect;

const TestErrors = error{
    Unexpected,
    FooBar,
};

fn returnsErrors() TestErrors!void {
    return TestErrors.FooBar;
}

const expectError = std.testing.expectError;
test "returns error" {
    try expectError(TestErrors.FooBar, returnsErrors());
}

// cast set of errors
const A = error{
    ConnectionError,
    AnotherError,
};

const B = error{
    ConnectionError,
};

fn castError(err: B) A {
    return err;
}

test "cast error" {
    const err = castError(B.ConnectionError);
    try expect(A.ConnectionError == err);
}

// catch - switch
fn throwError() ![]const u8 {
    return error.Foo;
}

fn testCatch() []const u8 {
    return throwError() catch |err| switch (err) {
        error.Foo => "test",
    };
}

test "catch" {
    try std.testing.expectEqualStrings(testCatch(), "test");
}

// errdefer
const Foo = struct {
    bar: u8,
};

fn testErrDefer(allocator: std.mem.Allocator) !Foo {
    const foo = try allocator.create(Foo);
    errdefer allocator.destroy(foo);

    try testReturnsError();

    return foo.*;
}

fn testReturnsError() !void {
    return error.Baz;
}

test "errdefer" {
    try expectError(error.Baz, testErrDefer(std.testing.allocator));
}

// unions
const TestUnion = union(enum) {
    hello: u8,
    world: u8,
};

test "unions" {
    const foo = TestUnion{
        .hello = 7,
    };

    switch (foo) {
        .hello => |val| try expect(val == 7),
        .world => try expect(true),
    }
}
