const commandhandler = @import("../command.zig");
const std = @import("std");
const Session = @import("../Session.zig");

const Allocator = std.mem.Allocator;
const Error = commandhandler.Error;

pub fn handle(session: *Session, _: []const u8, allocator: Allocator) Error!void {
    try commandhandler.sendMessage(session, "/tp to teleport, /sync to sync data from config\n", allocator);
    try commandhandler.sendMessage(session, "/refill to refill technique point after battle\n", allocator);
    try commandhandler.sendMessage(session, "/set to set gacha banner\n", allocator);
    try commandhandler.sendMessage(session, "/node to chage node in PF, AS, MoC\n", allocator);
    try commandhandler.sendMessage(session, "You can enter MoC, PF, AS via F4 menu\n", allocator);
    try commandhandler.sendMessage(session, "(If your Castorice technique enabled, you must enter battle by using Castorice's technique)\n", allocator);
}
