const std = @import("std");
const protocol = @import("protocol");
const Session = @import("../Session.zig");
const Packet = @import("../Packet.zig");
const commandhandler = @import("../command.zig");

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const CmdID = protocol.CmdID;

const B64Decoder = std.base64.standard.Decoder;

const EmojiList = [_]u32{};

pub fn onGetFriendListInfo(session: *Session, _: *const Packet, allocator: Allocator) !void {
    var rsp = protocol.GetFriendListInfoScRsp.init(allocator);
    rsp.retcode = 0;

    var assist_list = ArrayList(protocol.AssistSimpleInfo).init(allocator);
    try assist_list.appendSlice(&[_]protocol.AssistSimpleInfo{
        .{ .pos = 0, .level = 80, .avatar_id = 1403, .dressed_skin_id = 0 },
        .{ .pos = 1, .level = 80, .avatar_id = 1407, .dressed_skin_id = 0 },
        .{ .pos = 2, .level = 80, .avatar_id = 1001, .dressed_skin_id = 1100101 },
    });

    var friend = protocol.FriendSimpleInfo.init(allocator);
    friend.playing_state = .PLAYING_CHALLENGE_BOSS;
    friend.create_time = 0; //时间戳
    friend.remark_name = .{ .Const = "Ciallo～(∠・ω< )⌒☆" }; //好友自定义昵称
    friend.is_marked = true;
    friend.player_info = protocol.PlayerSimpleInfo{
        .signature = .{ .Const = "这是免费的模拟器，如果你花钱了，请立即退款并举报，最后Ciallo～(∠・ω< )⌒☆" },
        .nickname = .{ .Const = "Ciallo～(∠・ω< )⌒☆" },
        .level = 70,
        .uid = 2000,
        .head_icon = 200140,
        .ANPLLAOBFJI = 253000,
        .chat_bubble_id = 220008,
        .assist_simple_info_list = assist_list,
        .platform = protocol.PlatformType.ANDROID,
        .online_status = protocol.FriendOnlineStatus.FRIEND_ONLINE_STATUS_ONLINE,
    };
    try rsp.friend_list.append(friend);
    try session.send(CmdID.CmdGetFriendListInfoScRsp, rsp);
}
pub fn onChatEmojiList(session: *Session, _: *const Packet, allocator: Allocator) !void {
    var rsp = protocol.GetChatEmojiListScRsp.init(allocator);

    rsp.retcode = 0;
    try rsp.chat_emoji_list.appendSlice(&EmojiList);

    try session.send(CmdID.CmdGetChatEmojiListScRsp, rsp);
}
pub fn onPrivateChatHistory(session: *Session, _: *const Packet, allocator: Allocator) !void {
    var rsp = protocol.GetPrivateChatHistoryScRsp.init(allocator);

    rsp.retcode = 0;
    rsp.target_side = 1;
    rsp.contact_side = 2000;
    try rsp.chat_message_list.appendSlice(&[_]protocol.ChatMessageData{
        .{
            .content = .{ .Const = "使用 https://relic-builder.vercel.app/ 来设置配置" },
            .message_type = .MSG_TYPE_CUSTOM_TEXT,
            .create_time = 0,
            .sender_id = 2000,
        },
        .{
            .content = .{ .Const = "/help 查看命令列表" },
            .message_type = .MSG_TYPE_CUSTOM_TEXT,
            .create_time = 0,
            .sender_id = 2000,
        },
        .{
            .content = .{ .Const = "使用命令时，请先输入 '/'" },
            .message_type = .MSG_TYPE_CUSTOM_TEXT,
            .create_time = 0,
            .sender_id = 2000,
        },
        .{
            .extra_id = 122004,
            .message_type = .MSG_TYPE_EMOJI,
            .create_time = 0,
            .sender_id = 2000,
        },
    });

    try session.send(CmdID.CmdGetPrivateChatHistoryScRsp, rsp);
}
pub fn onSendMsg(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    std.debug.print("收到数据包：{any}\n", .{packet});
    const req = protocol.SendMsgCsReq.init(allocator);
    std.debug.print("已解码请求：{any}\n", .{req});
    std.debug.print("原始数据包正文：{any}\n", .{packet.body});
    const msg_text = switch (req.message_text) {
        .Empty => "",
        .Owned => |owned| owned.str,
        .Const => |const_str| const_str,
    };
    var msg_text2: []const u8 = "";
    if (packet.body.len > 9 and packet.body[2] == 47) {
        msg_text2 = packet.body[2 .. packet.body.len - 8];
    }
    std.debug.print("手动提取的消息文本：'{s}'\n", .{msg_text2});

    std.debug.print("消息文本 1: {any}\n", .{msg_text});

    if (msg_text2.len > 0) {
        if (std.mem.indexOf(u8, msg_text2, "/") != null) {
            std.debug.print("消息包含 \"/\"\n", .{});
            try commandhandler.handleCommand(session, msg_text2, allocator);
        } else {
            std.debug.print("消息不包含 \"/\"\n", .{});
            try commandhandler.sendMessage(session, msg_text2, allocator);
        }
    } else {
        std.debug.print("收到空消息\n", .{});
    }

    var rsp = protocol.SendMsgScRsp.init(allocator);
    rsp.retcode = 0;
    try session.send(CmdID.CmdSendMsgScRsp, rsp);
}
