const std = @import("std");
const builtin = @import("builtin");
const network = @import("network.zig");
const handlers = @import("handlers.zig");

// Windows API 声明
const windows = std.os.windows;
extern "kernel32" fn SetConsoleOutputCP(wCodePageID: windows.UINT) callconv(windows.WINAPI) windows.BOOL;
extern "kernel32" fn SetConsoleCP(wCodePageID: windows.UINT) callconv(windows.WINAPI) windows.BOOL;

pub const std_options = .{
    .log_level = switch (builtin.mode) {
        .Debug => .debug,
        else => .info,
    },
};

fn setConsoleUTF8() void {
    if (builtin.os.tag == .windows) {
        // 设置控制台输入和输出编码为 UTF-8 (代码页 65001)
        _ = SetConsoleOutputCP(65001);
        _ = SetConsoleCP(65001);
    }
}

pub fn main() !void {
    // 设置控制台为 UTF-8 编码
    setConsoleUTF8();

    try network.listen();
}
