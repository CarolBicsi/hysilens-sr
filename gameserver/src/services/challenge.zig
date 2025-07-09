const std = @import("std");
const protocol = @import("protocol");
const Session = @import("../Session.zig");
const Packet = @import("../Packet.zig");
const Config = @import("config.zig");
const Res_config = @import("res_config.zig");
const Data = @import("../data.zig");
const ChallegeStageManager = @import("../manager/battle_mgr.zig").ChallegeStageManager;
const ChallengeManager = @import("../manager/challenge_mgr.zig").ChallengeManager;
const SceneManager = @import("../manager/scene_mgr.zig").SceneManager;
const ChallengeSceneManager = @import("../manager/scene_mgr.zig").ChallengeSceneManager;
const LineupManager = @import("../manager/lineup_mgr.zig").LineupManager;
const ChallengeLineupManager = @import("../manager/lineup_mgr.zig").ChallengeLineupManager;
const NodeCheck = @import("../commands/value.zig");

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const CmdID = protocol.CmdID;

pub fn UidGenerator() type {
    return struct {
        current_id: u32,

        const Self = @This();

        pub fn init() Self {
            return Self{ .current_id = 100000 };
        }

        pub fn nextId(self: *Self) u32 {
            self.current_id +%= 1; // Using wrapping addition
            return self.current_id;
        }
    };
}

fn contains(list: *const std.ArrayListAligned(u32, null), value: u32) bool {
    for (list.items) |item| {
        if (item == value) {
            return true;
        }
    }
    return false;
}
pub var on_challenge: bool = false;

pub const ChallengeBlessing = ArrayList(u32);
pub var challenge_blessing: []const u32 = &.{};
pub var challenge_mode: u32 = 0;

pub var challenge_planeID: u32 = 0;
pub var challenge_floorID: u32 = 0;
pub var challenge_entryID: u32 = 0;
pub var challenge_worldID: u32 = 0;
pub var challenge_monsterID: u32 = 0;
pub var challenge_eventID: u32 = 0;
pub var challenge_groupID: u32 = 0;
pub var challenge_maze_groupID: u32 = 0;
pub var challenge_stageID: u32 = 0;

pub var challengeID: u32 = 0;
pub var challenge_buffID: u32 = 0;

pub const ChallengeAvatarList = ArrayList(u32);
pub var avatar_list: ChallengeAvatarList = ChallengeAvatarList.init(std.heap.page_allocator);

pub fn resetChallengeState() void {
    on_challenge = false;
    challenge_mode = 0;
    challenge_planeID = 0;
    challenge_floorID = 0;
    challenge_entryID = 0;
    challenge_worldID = 0;
    challenge_monsterID = 0;
    challenge_eventID = 0;
    challenge_groupID = 0;
    challenge_maze_groupID = 0;
    challenge_stageID = 0;
    challengeID = 0;
    challenge_buffID = 0;
    challenge_blessing = &.{};
    _ = avatar_list.clearRetainingCapacity();
}

pub fn onGetChallenge(session: *Session, _: *const Packet, allocator: Allocator) !void {
    const challenge_config = try Config.loadChallengeConfig(allocator, "resources/ChallengeMazeConfig.json");
    var rsp = protocol.GetChallengeScRsp.init(allocator);

    rsp.retcode = 0;
    for (challenge_config.challenge_config.items) |ids| {
        var challenge = protocol.Challenge.init(allocator);
        challenge.challenge_id = ids.id;
        challenge.star = 1;
        if (ids.id > 20000 and ids.id < 30000) {
            challenge.score_id = 40000;
            challenge.score_two = 40000;
        }
        try rsp.challenge_list.append(challenge);
    }

    try session.send(CmdID.CmdGetChallengeScRsp, rsp);
}
pub fn onGetChallengeGroupStatistics(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const req = try packet.getProto(protocol.GetChallengeGroupStatisticsCsReq, allocator);
    var rsp = protocol.GetChallengeGroupStatisticsScRsp.init(allocator);
    rsp.retcode = 0;
    rsp.group_id = req.group_id;
    try session.send(CmdID.CmdGetChallengeGroupStatisticsScRsp, rsp);
}
pub fn onLeaveChallenge(session: *Session, _: *const Packet, allocator: Allocator) !void {
    var lineup_mgr = LineupManager.init(allocator);
    const lineup = try lineup_mgr.createLineup();
    var scene_manager = SceneManager.init(allocator);
    const scene_info = try scene_manager.createScene(20422, 20422001, 2042201, 1025);
    try session.send(CmdID.CmdQuitBattleScNotify, protocol.QuitBattleScNotify{});
    try session.send(CmdID.CmdEnterSceneByServerScNotify, protocol.EnterSceneByServerScNotify{
        .reason = protocol.EnterSceneReason.ENTER_SCENE_REASON_NONE,
        .lineup = lineup,
        .scene = scene_info,
    });
    resetChallengeState();
    challenge_mode = 0;
    try session.send(CmdID.CmdLeaveChallengeScRsp, protocol.LeaveChallengeScRsp{
        .retcode = 0,
    });
}
pub fn onGetCurChallengeScRsp(session: *Session, _: *const Packet, allocator: Allocator) !void {
    var rsp = protocol.GetCurChallengeScRsp.init(allocator);
    var lineup_manager = ChallengeLineupManager.init(allocator);
    const lineup_info = try lineup_manager.createLineup(avatar_list);
    var challenge_manager = ChallengeManager.init(allocator);
    const cur_challenge_info = try challenge_manager.createChallenge(
        challengeID,
        challenge_buffID,
    );
    rsp.retcode = 0;
    if (on_challenge == true) {
        rsp.cur_challenge = cur_challenge_info;
        try rsp.lineup_list.append(lineup_info);

        std.debug.print("CURRENT CHALLENGE STAGE ID:{}\n", .{challenge_stageID});
        std.debug.print("CURRENT CHALLENGE LINEUP AVATAR ID:{}\n", .{avatar_list});
        std.debug.print("CURRENT CHALLENGE MONSTER ID:{}\n", .{challenge_monsterID});
        if (challenge_mode == 0) {
            std.debug.print("CURRENT CHALLENGE: {} MOC\n", .{challenge_mode});
        } else if (challenge_mode == 1) {
            std.debug.print("CURRENT CHALLENGE: {} PF\n", .{challenge_mode});
            std.debug.print("CURRENT CHALLENGE STAGE BLESSING ID:{}, SELECTED BLESSING ID:{}\n", .{ challenge_blessing[0], challenge_blessing[1] });
        } else {
            std.debug.print("CURRENT CHALLENGE: {} AS\n", .{challenge_mode});
            std.debug.print("CURRENT CHALLENGE STAGE BLESSING ID:{}, SELECTED BLESSING ID:{}\n", .{ challenge_blessing[0], challenge_blessing[1] });
        }
    } else {
        std.debug.print("CURRENT ON CHALLENGE STATE: {}\n", .{on_challenge});
    }

    try session.send(CmdID.CmdGetCurChallengeScRsp, rsp);
}
pub fn onStartChallenge(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const req = try packet.getProto(protocol.StartChallengeCsReq, allocator);
    var rsp = protocol.StartChallengeScRsp.init(allocator);

    challengeID = req.challenge_id;

    if (NodeCheck.challenge_node == 0) {
        for (req.first_lineup.items) |id| {
            try avatar_list.append(id);
        }
        if (challengeID > 20000 and challengeID < 30000)
            challenge_buffID = req.stage_info.?.KFELKJLDKEH.?.story_info.buff_one;
        if (challengeID > 30000)
            challenge_buffID = req.stage_info.?.KFELKJLDKEH.?.boss_info.buff_one;
    } else {
        for (req.second_lineup.items) |id| {
            try avatar_list.append(id);
        }
        if (challengeID > 20000 and challengeID < 30000)
            challenge_buffID = req.stage_info.?.KFELKJLDKEH.?.story_info.buff_two;
        if (challengeID > 30000)
            challenge_buffID = req.stage_info.?.KFELKJLDKEH.?.boss_info.buff_two;
    }
    var lineup_manager = ChallengeLineupManager.init(allocator);
    const lineup_info = try lineup_manager.createLineup(avatar_list);

    var challenge_manager = ChallengeManager.init(allocator);
    const cur_challenge_info = try challenge_manager.createChallenge(
        challengeID,
        challenge_buffID,
    );
    var scene_challenge_manager = ChallengeSceneManager.init(allocator);
    const scene_info = try scene_challenge_manager.createScene(
        avatar_list,
        challenge_planeID,
        challenge_floorID,
        challenge_entryID,
        challenge_worldID,
        challenge_monsterID,
        challenge_eventID,
        challenge_groupID,
        challenge_maze_groupID,
    );
    rsp.retcode = 0;
    rsp.scene = scene_info;
    rsp.cur_challenge = cur_challenge_info;
    try rsp.lineup_list.append(lineup_info);

    on_challenge = true;
    try session.send(CmdID.CmdStartChallengeScRsp, rsp);
    std.debug.print("SEND PLANE ID {} FLOOR ID {} ENTRY ID {} GROUP ID {} MAZE GROUP ID {}\n", .{
        challenge_planeID,
        challenge_floorID,
        challenge_entryID,
        challenge_groupID,
        challenge_maze_groupID,
    });
}
