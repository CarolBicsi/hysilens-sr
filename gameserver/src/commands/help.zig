const commandhandler = @import("../command.zig");
const std = @import("std");
const Session = @import("../Session.zig");

const Allocator = std.mem.Allocator;
const Error = commandhandler.Error;

pub fn handle(session: *Session, _: []const u8, allocator: Allocator) Error!void {
    try commandhandler.sendMessage(session, "/tp 传送，/sync 从配置同步数据\n", allocator);
    try commandhandler.sendMessage(session, "/refill 战斗后补充技能点\n", allocator);
    try commandhandler.sendMessage(session, "/set 设置抽卡卡池\n", allocator);
    try commandhandler.sendMessage(session, "/node 更改虚构叙事、模拟宇宙、忘却之庭的节点\n", allocator);
    try commandhandler.sendMessage(session, "你可以通过F4菜单进入忘却之庭、虚构叙事、模拟宇宙\n", allocator);
    try commandhandler.sendMessage(session, "(如果你启用了卡芙卡的秘技，你必须使用卡芙卡的秘技进入战斗)\n", allocator);
}
