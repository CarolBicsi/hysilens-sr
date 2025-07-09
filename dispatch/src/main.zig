const std = @import("std");
const builtin = @import("builtin");
const httpz = @import("httpz");
const protocol = @import("protocol");

const authentication = @import("authentication.zig");
const dispatch = @import("dispatch.zig");
const PORT = 21000;

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

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var server = try httpz.Server().init(allocator, .{ .port = PORT });
    defer server.stop();
    defer server.deinit();
    var router = server.router();

    router.get("/query_dispatch", dispatch.onQueryDispatch);
    router.get("/query_gateway", dispatch.onQueryGateway);
    router.post("/account/risky/api/check", authentication.onRiskyApiCheck);
    router.post("/:product_name/mdk/shield/api/login", authentication.onShieldLogin);
    router.post("/:product_name/mdk/shield/api/verify", authentication.onVerifyLogin);
    router.post("/:product_name/combo/granter/login/v2/login", authentication.onComboTokenReq);

    std.log.info("Dispatch is listening at localhost:{?}", .{server.config.port});
    try server.listen();
}
