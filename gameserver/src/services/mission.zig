const std = @import("std");
const protocol = @import("protocol");
const Session = @import("../Session.zig");
const Packet = @import("../Packet.zig");
const Data = @import("../data.zig");
const Config = @import("config.zig");

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const CmdID = protocol.CmdID;

pub fn onGetMissionStatus(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const req = try packet.getProto(protocol.GetMissionStatusCsReq, allocator);
    var rsp = protocol.GetMissionStatusScRsp.init(allocator);
    const main_mission_config = try Config.loadMainMissionConfig(allocator, "resources/MainMission.json");
    rsp.retcode = 0;
    for (req.sub_mission_id_list.items) |id| {
        try rsp.sub_mission_status_list.append(protocol.Mission{ .id = id, .status = protocol.MissionStatus.MISSION_FINISH, .progress = 1 });
    }
    for (main_mission_config.main_mission_config.items) |main_missionConf| {
        try rsp.finished_main_mission_id_list.append(main_missionConf.main_mission_id);
        try rsp.curversion_finished_main_mission_id_list.append(main_missionConf.main_mission_id);
    }
    try session.send(CmdID.CmdGetMissionStatusScRsp, rsp);
}

pub fn onGetTutorialGuideStatus(session: *Session, _: *const Packet, allocator: Allocator) !void {
    var rsp = protocol.GetTutorialGuideScRsp.init(allocator);
    const tutorial_guide_config = try Config.loadTutorialGuideConfig(allocator, "resources/TutorialGuideGroup.json");

    rsp.retcode = 0;
    for (tutorial_guide_config.tutorial_guide_config.items) |guideConf| {
        try rsp.tutorial_guide_list.append(protocol.TutorialGuide{ .id = guideConf.guide_group_id, .status = protocol.TutorialStatus.TUTORIAL_FINISH });
    }

    try session.send(CmdID.CmdGetTutorialGuideScRsp, rsp);
}

pub fn onGetTutorialStatus(session: *Session, _: *const Packet, allocator: Allocator) !void {
    var rsp = protocol.GetTutorialScRsp.init(allocator);
    const tutorial_guide_config = try Config.loadTutorialConfig(allocator, "resources/TutorialData.json");
    rsp.retcode = 0;
    for (tutorial_guide_config.tutorial_config.items) |tutorialConf| {
        try rsp.tutorial_list.append(protocol.Tutorial{ .id = tutorialConf.tutorial_id, .status = protocol.TutorialStatus.TUTORIAL_FINISH });
    }
    try session.send(CmdID.CmdGetTutorialScRsp, rsp);
}
pub fn onFinishTalkMission(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const req = try packet.getProto(protocol.FinishTalkMissionCsReq, allocator);
    var rsp = protocol.FinishTalkMissionScRsp.init(allocator);
    rsp.sub_mission_id = req.sub_mission_id;
    rsp.custom_value_list = req.custom_value_list;
    rsp.talk_str = req.talk_str;
    rsp.retcode = 0;
    try session.send(CmdID.CmdFinishTalkMissionScRsp, rsp);
}
// added this to auto detect new tutorial guide id
pub fn onUnlockTutorialGuide(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const req = try packet.getProto(protocol.UnlockTutorialGuideCsReq, allocator);
    var rsp = protocol.UnlockTutorialGuideScRsp.init(allocator);
    rsp.retcode = 0;
    std.debug.print("UNLOCK TUTORIAL GUIDE ID: {}\n", .{req.group_id});
    try session.send(CmdID.CmdUnlockTutorialGuideScRsp, rsp);
}
// added this to auto detect new tutorial id
pub fn onUnlockTutorial(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const req = try packet.getProto(protocol.UnlockTutorialCsReq, allocator);
    var rsp = protocol.UnlockTutorialScRsp.init(allocator);
    rsp.retcode = 0;
    std.debug.print("UNLOCK TUTORIAL ID: {}\n", .{req.tutorial_id});
    try session.send(CmdID.CmdUnlockTutorialScRsp, rsp);
}
