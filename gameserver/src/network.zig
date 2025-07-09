const std = @import("std");
const Session = @import("Session.zig");

const Allocator = std.mem.Allocator;

pub fn listen() !void {
    const addr = std.net.Address.parseIp4("0.0.0.0", 23301) catch unreachable;
    var listener = try addr.listen(.{
        .kernel_backlog = 100,
        .reuse_address = true,
    });

    std.log.info("服务器正在监听 {}", .{listener.listen_address});

    while (true) {
        const conn = listener.accept() catch continue;
        errdefer conn.stream.close();

        const thread = try std.Thread.spawn(.{}, runSession, .{ conn.address, conn.stream });
        thread.detach();
    }
}

fn runSession(address: std.net.Address, stream: std.net.Stream) !void {
    std.log.info("来自 {} 的新连接", .{address});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) std.log.err("检测到来自会话 {} 的内存泄漏", .{address});

    const allocator = gpa.allocator();

    const session = try allocator.create(Session);
    session.* = Session.init(address, stream, allocator);

    if (session.*.run()) |_| {
        std.log.info("来自 {} 的客户端已断开连接", .{address});
    } else |err| {
        std.log.err("会话因错误断开连接: {}", .{err});
    }

    allocator.destroy(session);
}
