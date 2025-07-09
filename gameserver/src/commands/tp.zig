const commandhandler = @import("../command.zig");
const std = @import("std");
const Session = @import("../Session.zig");
const protocol = @import("protocol");
const Config = @import("../services/config.zig");
const Res_config = @import("../services/res_config.zig");
const LineupManager = @import("../manager/lineup_mgr.zig").LineupManager;
const SceneManager = @import("../manager/scene_mgr.zig").SceneManager;

const Allocator = std.mem.Allocator;
const CmdID = protocol.CmdID;
const Error = commandhandler.Error;

pub fn handle(session: *Session, args: []const u8, allocator: Allocator) Error!void {
    var arg_iter = std.mem.split(u8, args, " ");
    const entry_id_str = arg_iter.next() orelse {
        try commandhandler.sendMessage(session, "错误：缺少参数。\n用法：/tp <entry_id> [plane_id] [floor_id]", allocator);
        return;
    };
    const entry_id = std.fmt.parseInt(u32, entry_id_str, 10) catch {
        try commandhandler.sendMessage(session, "错误：无效的入口ID。请提供一个有效的32位无符号整数。", allocator);
        return;
    };
    var plane_id: ?u32 = null;
    if (arg_iter.next()) |plane_id_str| {
        plane_id = std.fmt.parseInt(u32, plane_id_str, 10) catch {
            try commandhandler.sendMessage(session, "错误：无效的平面ID。请提供一个有效的32位无符号整数。", allocator);
            return;
        };
    }
    var floor_id: ?u32 = null;
    if (arg_iter.next()) |floor_id_str| {
        floor_id = std.fmt.parseInt(u32, floor_id_str, 10) catch {
            try commandhandler.sendMessage(session, "错误：无效的楼层ID。请提供一个有效的32位无符号整数。", allocator);
            return;
        };
    }
    var tp_msg = try std.fmt.allocPrint(allocator, "传送到入口ID：{d}", .{entry_id});
    if (plane_id) |pid| {
        tp_msg = try std.fmt.allocPrint(allocator, "{s}，平面ID：{d}", .{ tp_msg, pid });
    }
    if (floor_id) |fid| {
        tp_msg = try std.fmt.allocPrint(allocator, "{s}，楼层ID：{d}", .{ tp_msg, fid });
    }

    try commandhandler.sendMessage(session, std.fmt.allocPrint(allocator, "传送到入口ID：{d} {any} {any}\n", .{ entry_id, plane_id, floor_id }) catch "格式化消息错误", allocator);

    var planeID: u32 = 0;
    var floorID: u32 = 0;
    if (plane_id) |pid| planeID = pid;
    if (floor_id) |fid| floorID = fid;
    var scene_manager = SceneManager.init(allocator);
    const scene_info = try scene_manager.createScene(planeID, floorID, entry_id, 0);
    var lineup_mgr = LineupManager.init(allocator);
    const lineup = try lineup_mgr.createLineup();
    try session.send(CmdID.CmdEnterSceneByServerScNotify, protocol.EnterSceneByServerScNotify{
        .reason = protocol.EnterSceneReason.ENTER_SCENE_REASON_NONE,
        .lineup = lineup,
        .scene = scene_info,
    });
}
