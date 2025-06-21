const std = @import("std");
const c = @cImport({
    @cDefine("_NO_CRT_STDIO_INLINE", "1");
    @cInclude("stdio.h");
    @cInclude("spng.h");
});

fn getImageHeader(ctx: *c.spng_ctx) !c.spng_ihdr {
    var imageHeader: c.spng_ihdr = undefined;
    if (c.spng_get_ihdr(ctx, &imageHeader) != 0) {
        return error.CouldNotGetImageHeader;
    }

    return imageHeader;
}

fn calcOutputSize(ctx: *c.spng_ctx) !u64 {
    var outputSize: u64 = 0;
    if (c.spng_decoded_image_size(ctx, c.SPNG_FMT_RGBA8, &outputSize) != 0) {
        return error.CouldNotCalcOutputSize;
    }

    return outputSize;
}

fn readToBuffer(ctx: *c.spng_ctx, buffer: []u8) !void {
    const status = c.spng_decode_image(ctx, buffer.ptr, buffer.len, c.SPNG_FMT_RGBA8, 0);

    if (status != 0) {
        return error.CouldNotDecodeImage;
    }
}

fn applyGrayscale(buffer: []u8) !void {
    const redCoef: f16 = 0.2126;
    const greenCoef: f16 = 0.7152;
    const blueCoef: f16 = 0.0722;

    var i: u64 = 0;
    while (i < buffer.len) : (i += 4) {
        const red: f16 = @floatFromInt(buffer[i]);
        const green: f16 = @floatFromInt(buffer[i + 1]);
        const blue: f16 = @floatFromInt(buffer[i + 2]);

        const linLum: u8 = @intFromFloat((red * redCoef) + (green * greenCoef) + (blue * blueCoef));

        buffer[i] = linLum;
        buffer[i + 1] = linLum;
        buffer[i + 2] = linLum;
    }
}

fn saveImageFromBuffer(buffer: []u8, header: *c.spng_ihdr, path: []const u8) !void {
    const fileDescriptor = c.fopen(path.ptr, "wb");
    if (fileDescriptor == null) {
        return error.CouldNotOpenFile;
    }
    defer {
        if (c.fclose(fileDescriptor) != 0) {
            @panic("Could not close file descriptor!");
        }
    }

    const ctx = c.spng_ctx_new(c.SPNG_CTX_ENCODER) orelse unreachable;
    defer c.spng_ctx_free(ctx);

    _ = c.spng_set_png_file(ctx, fileDescriptor);
    _ = c.spng_set_ihdr(ctx, header);

    const status = c.spng_encode_image(ctx, buffer.ptr, buffer.len, c.SPNG_FMT_PNG, c.SPNG_ENCODE_FINALIZE);
    if (status != 0) {
        return error.CouldNotEncodeImage;
    }
}

pub fn main() !void {
    var args = std.process.args();
    _ = args.skip();
    const origPath = args.next() orelse @panic("Original image path is not provided!");
    const newPath = args.next() orelse @panic("New image path is not provided!");

    const fileDescriptor = c.fopen(origPath, "rb");
    if (fileDescriptor == null) {
        @panic("Could not open file!");
    }
    defer {
        if (c.fclose(fileDescriptor) != 0) {
            @panic("Could not close file descriptor");
        }
    }

    const ctx = c.spng_ctx_new(0) orelse unreachable;
    if (c.spng_set_png_file(ctx, @ptrCast(fileDescriptor)) != 0) {
        @panic("Could not set png image");
    }

    var gpAllocator: std.heap.GeneralPurposeAllocator(.{}) = .init;
    const allocator = gpAllocator.allocator();
    const size = try calcOutputSize(ctx);
    const buffer = try allocator.alloc(u8, size);
    defer allocator.free(buffer);

    try readToBuffer(ctx, buffer);
    try applyGrayscale(buffer);
    var origHeader = try getImageHeader(ctx);
    try saveImageFromBuffer(buffer, &origHeader, newPath);
}
