const std = @import("std");
const c = @cImport({
    @cDefine("_NO_CRT_STDIO_INLINE", "1");
    @cInclude("stdio.h");
    @cInclude("spng.h");
});

const path = "pedro_pascal.png";

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

pub fn main() !void {
    const fileDescriptor = c.fopen(path, "rb");
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

    std.debug.print("{any}\n", .{buffer[0..12]});
}
