const commandhandler = @import("../command.zig");
const std = @import("std");
const Session = @import("../Session.zig");
const protocol = @import("protocol");
const Packet = @import("../Packet.zig");
const Config = @import("../services/config.zig");
const Data = @import("../data.zig");
const LineupManager = @import("../manager/lineup_mgr.zig").LineupManager;

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const CmdID = protocol.CmdID;
const Error = commandhandler.Error;

pub fn onRefill(session: *Session, _: []const u8, allocator: Allocator) Error!void {
    try commandhandler.sendMessage(session, "补充技能点\n", allocator);
    var sync = protocol.SyncLineupNotify.init(allocator);
    var lineup_mgr = LineupManager.init(allocator);
    const lineup = try lineup_mgr.createLineup();
    sync.lineup = lineup;
    try session.send(CmdID.CmdSyncLineupNotify, sync);
}
