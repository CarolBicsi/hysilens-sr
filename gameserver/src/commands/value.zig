const commandhandler = @import("../command.zig");
const std = @import("std");
const Session = @import("../Session.zig");

const Allocator = std.mem.Allocator;
const Error = commandhandler.Error;

pub var challenge_node: u32 = 0;
pub var StandardBanner = [_]u32{ 1003, 1004, 1101, 1104, 1209, 1211 };
pub var RateUp = [_]u32{1410};
pub var RateUpFourStars = [_]u32{ 1210, 1108, 1207 };

pub fn handle(session: *Session, _: []const u8, allocator: Allocator) Error!void {
    try commandhandler.sendMessage(session, "聊天测试命令\n", allocator);
}
pub fn challengeNode(session: *Session, _: []const u8, allocator: Allocator) Error!void {
    if (challenge_node == 0) {
        try commandhandler.sendMessage(session, "更改挑战节点 2\n", allocator);
        challenge_node = challenge_node + 1;
    } else {
        try commandhandler.sendMessage(session, "更改挑战节点 1\n", allocator);
        challenge_node = challenge_node - 1;
    }
}
pub fn setGachaCommand(session: *Session, args: []const u8, allocator: Allocator) Error!void {
    var arg_iter = std.mem.split(u8, args, " ");
    const command = arg_iter.next() orelse {
        try commandhandler.sendMessage(session, "错误：缺少子命令。用法：/set <子命令> [参数]", allocator);
        return;
    };
    if (std.mem.eql(u8, command, "standard")) {
        try standard(session, &arg_iter, allocator);
    } else if (std.mem.eql(u8, command, "rateup")) {
        const next = arg_iter.next();
        if (next) |rateup_number| {
            if (std.mem.eql(u8, rateup_number, "5")) {
                try gacha5Stars(session, &arg_iter, allocator);
            } else if (std.mem.eql(u8, rateup_number, "4")) {
                try gacha4Stars(session, &arg_iter, allocator);
            } else {
                try commandhandler.sendMessage(session, "错误：无效的限定数字。请使用 4（四星）或 5（五星）。", allocator);
            }
        } else {
            try commandhandler.sendMessage(session, "错误：限定缺少数字。用法：/set rateup <数字>", allocator);
        }
    } else {
        try commandhandler.sendMessage(session, "错误：未知子命令。可用命令：standard、rateup 5、rateup 4", allocator);
    }
}

fn standard(session: *Session, arg_iter: *std.mem.SplitIterator(u8, .sequence), allocator: Allocator) Error!void {
    var avatar_ids: [6]u32 = undefined;
    var count: usize = 0;
    while (count < 6) {
        if (arg_iter.next()) |avatar_id_str| {
            const id = std.fmt.parseInt(u32, avatar_id_str, 10) catch {
                return sendErrorMessage(session, "错误：无效的角色ID。请提供一个有效的32位无符号整数。", allocator);
            };
            if (!isValidAvatarId(id)) {
                return sendErrorMessage(session, "错误：无效的角色ID格式。", allocator);
            }
            avatar_ids[count] = id;
            count += 1;
        } else {
            break;
        }
    }
    if (arg_iter.next() != null or count != 6) {
        return sendErrorMessage(session, "错误：你必须提供恰好6个角色ID。", allocator);
    }
    @memcpy(&StandardBanner, &avatar_ids);
    const msg = try std.fmt.allocPrint(allocator, "设置常驻卡池ID为：{d}、{d}、{d}、{d}、{d}、{d}", .{ avatar_ids[0], avatar_ids[1], avatar_ids[2], avatar_ids[3], avatar_ids[4], avatar_ids[5] });
    try commandhandler.sendMessage(session, msg, allocator);
}
fn gacha4Stars(session: *Session, arg_iter: *std.mem.SplitIterator(u8, .sequence), allocator: Allocator) Error!void {
    var avatar_ids: [3]u32 = undefined;
    var count: usize = 0;
    while (count < 3) {
        if (arg_iter.next()) |avatar_id_str| {
            const id = std.fmt.parseInt(u32, avatar_id_str, 10) catch {
                return sendErrorMessage(session, "错误：无效的角色ID。请提供一个有效的32位无符号整数。", allocator);
            };
            if (!isValidAvatarId(id)) {
                return sendErrorMessage(session, "错误：无效的角色ID格式。", allocator);
            }
            avatar_ids[count] = id;
            count += 1;
        } else {
            break;
        }
    }
    if (arg_iter.next() != null or count != 3) {
        return sendErrorMessage(session, "错误：你必须提供恰好3个角色ID。", allocator);
    }
    @memcpy(&RateUpFourStars, &avatar_ids);
    const msg = try std.fmt.allocPrint(allocator, "设置4星限定ID为：{d}、{d}、{d}", .{ avatar_ids[0], avatar_ids[1], avatar_ids[2] });
    try commandhandler.sendMessage(session, msg, allocator);
}
fn gacha5Stars(session: *Session, arg_iter: *std.mem.SplitIterator(u8, .sequence), allocator: Allocator) Error!void {
    var avatar_ids: [1]u32 = undefined;
    if (arg_iter.next()) |avatar_id_str| {
        const id = std.fmt.parseInt(u32, avatar_id_str, 10) catch {
            return sendErrorMessage(session, "错误：无效的角色ID。请提供一个有效的32位无符号整数。", allocator);
        };
        if (!isValidAvatarId(id)) {
            return sendErrorMessage(session, "错误：无效的角色ID格式。", allocator);
        }
        avatar_ids[0] = id;
    } else {
        return sendErrorMessage(session, "错误：你必须提供一个限定角色ID。", allocator);
    }
    if (arg_iter.next() != null) {
        return sendErrorMessage(session, "错误：只允许一个限定角色ID。", allocator);
    }
    @memcpy(&RateUp, &avatar_ids);
    const msg = try std.fmt.allocPrint(allocator, "设置限定ID为：{d}", .{avatar_ids[0]});
    try commandhandler.sendMessage(session, msg, allocator);
}
fn sendErrorMessage(session: *Session, message: []const u8, allocator: Allocator) Error!void {
    try commandhandler.sendMessage(session, message, allocator);
}
fn isValidAvatarId(avatar_id: u32) bool {
    return avatar_id >= 1000 and avatar_id <= 9999;
}
