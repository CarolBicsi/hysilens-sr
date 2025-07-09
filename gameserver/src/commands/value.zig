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
    try commandhandler.sendMessage(session, "Test Command for Chat\n", allocator);
}
pub fn challengeNode(session: *Session, _: []const u8, allocator: Allocator) Error!void {
    if (challenge_node == 0) {
        try commandhandler.sendMessage(session, "Change Challenge Node 2 \n", allocator);
        challenge_node = challenge_node + 1;
    } else {
        try commandhandler.sendMessage(session, "Change Challenge Node 1 \n", allocator);
        challenge_node = challenge_node - 1;
    }
}
pub fn setGachaCommand(session: *Session, args: []const u8, allocator: Allocator) Error!void {
    var arg_iter = std.mem.split(u8, args, " ");
    const command = arg_iter.next() orelse {
        try commandhandler.sendMessage(session, "Error: Missing sub-command. Usage: /set <sub-command> [arguments]", allocator);
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
                try commandhandler.sendMessage(session, "Error: Invalid rateup number. Please use 4 (four stars) or 5 (5 stars).", allocator);
            }
        } else {
            try commandhandler.sendMessage(session, "Error: Missing number for rateup. Usage: /set rateup <number>", allocator);
        }
    } else {
        try commandhandler.sendMessage(session, "Error: Unknown sub-command. Available: standard, rateup 5, rateup 4", allocator);
    }
}

fn standard(session: *Session, arg_iter: *std.mem.SplitIterator(u8, .sequence), allocator: Allocator) Error!void {
    var avatar_ids: [6]u32 = undefined;
    var count: usize = 0;
    while (count < 6) {
        if (arg_iter.next()) |avatar_id_str| {
            const id = std.fmt.parseInt(u32, avatar_id_str, 10) catch {
                return sendErrorMessage(session, "Error: Invalid avatar ID. Please provide a valid unsigned 32-bit integer.", allocator);
            };
            if (!isValidAvatarId(id)) {
                return sendErrorMessage(session, "Error: Invalid Avatar ID format.", allocator);
            }
            avatar_ids[count] = id;
            count += 1;
        } else {
            break;
        }
    }
    if (arg_iter.next() != null or count != 6) {
        return sendErrorMessage(session, "Error: You must provide exactly 6 avatar IDs.", allocator);
    }
    @memcpy(&StandardBanner, &avatar_ids);
    const msg = try std.fmt.allocPrint(allocator, "Set standard banner ID to: {d}, {d}, {d}, {d}, {d}, {d}", .{ avatar_ids[0], avatar_ids[1], avatar_ids[2], avatar_ids[3], avatar_ids[4], avatar_ids[5] });
    try commandhandler.sendMessage(session, msg, allocator);
}
fn gacha4Stars(session: *Session, arg_iter: *std.mem.SplitIterator(u8, .sequence), allocator: Allocator) Error!void {
    var avatar_ids: [3]u32 = undefined;
    var count: usize = 0;
    while (count < 3) {
        if (arg_iter.next()) |avatar_id_str| {
            const id = std.fmt.parseInt(u32, avatar_id_str, 10) catch {
                return sendErrorMessage(session, "Error: Invalid avatar ID. Please provide a valid unsigned 32-bit integer.", allocator);
            };
            if (!isValidAvatarId(id)) {
                return sendErrorMessage(session, "Error: Invalid Avatar ID format.", allocator);
            }
            avatar_ids[count] = id;
            count += 1;
        } else {
            break;
        }
    }
    if (arg_iter.next() != null or count != 3) {
        return sendErrorMessage(session, "Error: You must provide exactly 3 avatar IDs.", allocator);
    }
    @memcpy(&RateUpFourStars, &avatar_ids);
    const msg = try std.fmt.allocPrint(allocator, "Set 4 star rate up ID to: {d}, {d}, {d}", .{ avatar_ids[0], avatar_ids[1], avatar_ids[2] });
    try commandhandler.sendMessage(session, msg, allocator);
}
fn gacha5Stars(session: *Session, arg_iter: *std.mem.SplitIterator(u8, .sequence), allocator: Allocator) Error!void {
    var avatar_ids: [1]u32 = undefined;
    if (arg_iter.next()) |avatar_id_str| {
        const id = std.fmt.parseInt(u32, avatar_id_str, 10) catch {
            return sendErrorMessage(session, "Error: Invalid avatar ID. Please provide a valid unsigned 32-bit integer.", allocator);
        };
        if (!isValidAvatarId(id)) {
            return sendErrorMessage(session, "Error: Invalid Avatar ID format.", allocator);
        }
        avatar_ids[0] = id;
    } else {
        return sendErrorMessage(session, "Error: You must provide a rate-up avatar ID.", allocator);
    }
    if (arg_iter.next() != null) {
        return sendErrorMessage(session, "Error: Only one rate-up avatar ID is allowed.", allocator);
    }
    @memcpy(&RateUp, &avatar_ids);
    const msg = try std.fmt.allocPrint(allocator, "Set rate up ID to: {d}", .{avatar_ids[0]});
    try commandhandler.sendMessage(session, msg, allocator);
}
fn sendErrorMessage(session: *Session, message: []const u8, allocator: Allocator) Error!void {
    try commandhandler.sendMessage(session, message, allocator);
}
fn isValidAvatarId(avatar_id: u32) bool {
    return avatar_id >= 1000 and avatar_id <= 9999;
}
