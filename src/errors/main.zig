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
