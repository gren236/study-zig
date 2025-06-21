const c = @cImport({
    @cDefine("_NO_CRT_STDIO_INLINE", "1");
    @cInclude("stdio.h");
    @cInclude("math.h");
});

pub fn main() !void {
    const x: f32 = 123.34;
    const y = c.powf(x, @as(f32, 2.5));
    _ = c.printf("%.3f\n", y);
}
