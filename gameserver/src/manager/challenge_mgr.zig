const std = @import("std");
const protocol = @import("protocol");
const Session = @import("../Session.zig");
const Packet = @import("../Packet.zig");
const Config = @import("../services/config.zig");
const Data = @import("../data.zig");
const ChallengeData = @import("../services/challenge.zig");
const NodeCheck = @import("../commands/value.zig");

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const CmdID = protocol.CmdID;

fn contains(list: *const std.ArrayListAligned(u32, null), value: u32) bool {
    for (list.items) |item| {
        if (item == value) {
            return true;
        }
    }
    return false;
}

pub const ChallengeManager = struct {
    allocator: std.mem.Allocator,
    pub fn init(allocator: std.mem.Allocator) ChallengeManager {
        return ChallengeManager{ .allocator = allocator };
    }
    pub fn createChallenge(
        self: *ChallengeManager,
        challenge_id: u32,
        buff_id: u32,
    ) !protocol.CurChallenge {
        const challenge_config = try Config.loadChallengeConfig(self.allocator, "resources/ChallengeMazeConfig.json");
        const entrance_config = try Config.loadMapEntranceConfig(self.allocator, "resources/MapEntrance.json");
        const maze_config = try Config.loadMazePlaneConfig(self.allocator, "resources/MazePlane.json");

        var challenge_blessing_list = ChallengeData.ChallengeBlessing{
            .allocator = std.heap.page_allocator,
            .items = &.{},
            .capacity = 0,
        };

        var cur_challenge_info = protocol.CurChallenge.init(self.allocator);
        cur_challenge_info.challenge_id = challenge_id;
        cur_challenge_info.score_id = if (challenge_id > 20000 and challenge_id < 30000) 40000 else 0;
        cur_challenge_info.score_two = 0;
        cur_challenge_info.status = protocol.ChallengeStatus.CHALLENGE_DOING;
        cur_challenge_info.extra_lineup_type = if (NodeCheck.challenge_node == 0) protocol.ExtraLineupType.LINEUP_CHALLENGE else protocol.ExtraLineupType.LINEUP_CHALLENGE_2;
        if (NodeCheck.challenge_node == 0) {
            for (challenge_config.challenge_config.items) |challengeConf| {
                if (challengeConf.id == challenge_id) {
                    std.debug.print("跟踪质询 ID {} 的配置 ID {}\n", .{ challengeConf.id, challenge_id });
                    for (entrance_config.map_entrance_config.items) |entrance| {
                        if (entrance.id == challengeConf.map_entrance_id) {
                            for (maze_config.maze_plane_config.items) |maze| {
                                if (contains(&maze.floor_id_list, entrance.floor_id)) {
                                    if (challenge_id > 20000 and challenge_id < 30000) {
                                        var story_buff = protocol.ChallengeStoryBuffList{
                                            .buff_list = ArrayList(u32).init(self.allocator),
                                        };
                                        try story_buff.buff_list.append(challengeConf.maze_buff_id);
                                        try story_buff.buff_list.append(buff_id);
                                        try challenge_blessing_list.appendSlice(story_buff.buff_list.items);
                                        cur_challenge_info.stage_info = .{
                                            .KFELKJLDKEH = .{
                                                .cur_story_buffs = story_buff,
                                            },
                                        };
                                        ChallengeData.challenge_mode = 1;
                                    } else if (challenge_id > 30000) {
                                        var boss_buff = protocol.ChallengeBossBuffList{
                                            .buff_list = ArrayList(u32).init(self.allocator),
                                            .challenge_boss_const = 1,
                                        };
                                        try boss_buff.buff_list.append(challengeConf.maze_buff_id);
                                        try boss_buff.buff_list.append(buff_id);
                                        try challenge_blessing_list.appendSlice(boss_buff.buff_list.items);
                                        cur_challenge_info.stage_info = .{
                                            .KFELKJLDKEH = .{
                                                .cur_boss_buffs = boss_buff,
                                            },
                                        };
                                        ChallengeData.challenge_mode = 2;
                                    }
                                    ChallengeData.challenge_floorID = entrance.floor_id;
                                    ChallengeData.challenge_worldID = maze.world_id;
                                    ChallengeData.challenge_monsterID = challengeConf.npc_monster_id_list1.items[challengeConf.npc_monster_id_list1.items.len - 1];
                                    ChallengeData.challenge_eventID = challengeConf.event_id_list1.items[challengeConf.event_id_list1.items.len - 1];
                                    ChallengeData.challenge_groupID = challengeConf.maze_group_id1;
                                    ChallengeData.challenge_maze_groupID = challengeConf.maze_group_id1;
                                    ChallengeData.challenge_planeID = maze.challenge_plane_id;
                                    ChallengeData.challenge_entryID = challengeConf.map_entrance_id;
                                }
                            }
                        }
                    }
                }
            }
        } else {
            for (challenge_config.challenge_config.items) |challengeConf| {
                if (challengeConf.id == challenge_id) {
                    std.debug.print("跟踪质询 ID {} 的配置 ID {}\n", .{ challengeConf.id, challenge_id });
                    for (entrance_config.map_entrance_config.items) |entrance| {
                        if (entrance.id == challengeConf.map_entrance_id2) {
                            for (maze_config.maze_plane_config.items) |maze| {
                                if (contains(&maze.floor_id_list, entrance.floor_id)) {
                                    if (challengeConf.maze_group_id2) |id| {
                                        if (challenge_id > 20000 and challenge_id < 30000) {
                                            var story_buff = protocol.ChallengeStoryBuffList{
                                                .buff_list = ArrayList(u32).init(self.allocator),
                                            };
                                            try story_buff.buff_list.append(challengeConf.maze_buff_id);
                                            try story_buff.buff_list.append(buff_id);
                                            try challenge_blessing_list.appendSlice(story_buff.buff_list.items);
                                            cur_challenge_info.stage_info = .{
                                                .KFELKJLDKEH = .{
                                                    .cur_story_buffs = story_buff,
                                                },
                                            };
                                            ChallengeData.challenge_mode = 1;
                                        } else if (challenge_id > 30000) {
                                            var boss_buff = protocol.ChallengeBossBuffList{
                                                .buff_list = ArrayList(u32).init(self.allocator),
                                                .challenge_boss_const = 1,
                                            };
                                            try boss_buff.buff_list.append(challengeConf.maze_buff_id);
                                            try boss_buff.buff_list.append(buff_id);
                                            try challenge_blessing_list.appendSlice(boss_buff.buff_list.items);
                                            cur_challenge_info.stage_info = .{
                                                .KFELKJLDKEH = .{
                                                    .cur_boss_buffs = boss_buff,
                                                },
                                            };
                                            ChallengeData.challenge_mode = 2;
                                        }
                                        ChallengeData.challenge_floorID = entrance.floor_id;
                                        ChallengeData.challenge_worldID = maze.world_id;
                                        ChallengeData.challenge_monsterID = challengeConf.npc_monster_id_list2.items[challengeConf.npc_monster_id_list2.items.len - 1];
                                        ChallengeData.challenge_eventID = challengeConf.event_id_list2.items[challengeConf.event_id_list2.items.len - 1];
                                        ChallengeData.challenge_groupID = id;
                                        ChallengeData.challenge_maze_groupID = id;
                                        ChallengeData.challenge_planeID = maze.challenge_plane_id;
                                        ChallengeData.challenge_entryID = challengeConf.map_entrance_id2;
                                    } else {
                                        std.debug.print("此质询 ID：{} 不支持第 2 个节点。请执行命令 /node 切换回第一个节点\n", .{challenge_id});
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        ChallengeData.challenge_blessing = challenge_blessing_list.items[0..challenge_blessing_list.items.len];
        ChallengeData.challenge_stageID = ChallengeData.challenge_eventID;
        return cur_challenge_info;
    }
};
