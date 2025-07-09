const std = @import("std");
const protocol = @import("protocol");
const Session = @import("../Session.zig");
const Packet = @import("../Packet.zig");
const Config = @import("../services/config.zig");
const Res_config = @import("../services/res_config.zig");
const Data = @import("../data.zig");

const UidGenerator = @import("../services/item.zig").UidGenerator;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const CmdID = protocol.CmdID;

pub const SceneManager = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) SceneManager {
        return SceneManager{ .allocator = allocator };
    }

    pub fn createScene(
        self: *SceneManager,
        plane_id: u32,
        floor_id: u32,
        entry_id: u32,
        teleport_id: u32,
    ) !protocol.SceneInfo {
        const config = try Config.loadGameConfig(self.allocator, "config.json");
        const res_config = try Res_config.anchorLoader(self.allocator, "resources/res.json");
        var generator = UidGenerator().init();
        var scene_info = protocol.SceneInfo.init(self.allocator);
        scene_info.game_mode_type = 1;
        scene_info.plane_id = plane_id;
        scene_info.floor_id = floor_id;
        scene_info.entry_id = entry_id;
        scene_info.leader_entity_id = config.avatar_config.items[0].id + 100000;
        scene_info.world_id = 501;
        scene_info.client_pos_version = 1;
        var group_map = std.AutoHashMap(u32, protocol.SceneEntityGroupInfo).init(self.allocator);
        defer group_map.deinit();

        for (res_config.scene_config.items) |sceneConf| {
            for (sceneConf.teleports.items) |teleConf| {
                if (teleConf.teleportId == teleport_id) {
                    var scene_group = protocol.SceneEntityGroupInfo.init(self.allocator);
                    scene_group.state = 1;
                    for (config.avatar_config.items) |avatarConf| {
                        try scene_group.entity_list.append(.{
                            .inst_id = 1,
                            .entity_id = @intCast(avatarConf.id + 100000),
                            .entity = .{ .actor = .{
                                .base_avatar_id = avatarConf.id,
                                .avatar_type = .AVATAR_FORMAL_TYPE,
                                .uid = 0,
                                .map_layer = 0,
                            } },
                            .motion = .{
                                .pos = .{ .x = teleConf.pos.x, .y = teleConf.pos.y, .z = teleConf.pos.z },
                                .rot = .{ .x = teleConf.rot.x, .y = teleConf.rot.y, .z = teleConf.rot.z },
                            },
                        });
                    }
                    try scene_info.entity_group_list.append(scene_group);
                }
            }
            if (scene_info.plane_id != 10000 and scene_info.plane_id != 10202 and sceneConf.planeID == scene_info.plane_id) {
                for (sceneConf.props.items) |propConf| {
                    var scene_group = try getOrCreateGroup(&group_map, propConf.groupId, self.allocator);
                    var prop_info = protocol.ScenePropInfo.init(self.allocator);
                    prop_info.prop_id = propConf.propId;
                    prop_info.prop_state = propConf.propState;
                    try scene_group.entity_list.append(.{
                        .entity = .{ .prop = prop_info },
                        .group_id = scene_group.group_id,
                        .inst_id = propConf.instId,
                        .entity_id = 1000 + generator.nextId(),
                        .motion = .{
                            .pos = .{ .x = propConf.pos.x, .y = propConf.pos.y, .z = propConf.pos.z },
                            .rot = .{ .x = propConf.rot.x, .y = propConf.rot.y, .z = propConf.rot.z },
                        },
                    });
                }
                for (sceneConf.monsters.items) |monsConf| {
                    var scene_group = try getOrCreateGroup(&group_map, monsConf.groupId, self.allocator);
                    var monster_info = protocol.SceneNpcMonsterInfo.init(self.allocator);
                    monster_info.monster_id = monsConf.monsterId;
                    monster_info.event_id = monsConf.eventId;
                    monster_info.world_level = 6;
                    try scene_group.entity_list.append(.{
                        .entity = .{ .npc_monster = monster_info },
                        .group_id = scene_group.group_id,
                        .inst_id = monsConf.instId,
                        .entity_id = if ((monsConf.monsterId / 1000) % 10 == 3) monster_info.monster_id else generator.nextId(),
                        .motion = .{
                            .pos = .{ .x = monsConf.pos.x, .y = monsConf.pos.y, .z = monsConf.pos.z },
                            .rot = .{ .x = monsConf.rot.x, .y = monsConf.rot.y, .z = monsConf.rot.z },
                        },
                    });
                }
            }
        }
        var iter = group_map.iterator();
        while (iter.next()) |entry| {
            try scene_info.entity_group_list.append(entry.value_ptr.*);
            try scene_info.entity_list.appendSlice(entry.value_ptr.entity_list.items);
            try scene_info.DJBIBIJMEBH.append(entry.value_ptr.group_id);
            try scene_info.custom_data_list.append(protocol.CustomSaveData{
                .group_id = entry.value_ptr.group_id,
            });
            try scene_info.group_state_list.append(protocol.SceneGroupState{
                .group_id = entry.value_ptr.group_id,
                .state = 0,
                .is_default = true,
            });
        }
        const ranges = [_][2]usize{
            .{ 0, 101 },
            .{ 10000, 10051 },
            .{ 20000, 20001 },
            .{ 30000, 30020 },
        };
        for (ranges) |range| {
            for (range[0]..range[1]) |i| {
                try scene_info.lighten_section_list.append(@intCast(i));
            }
        }
        return scene_info;
    }
    fn getOrCreateGroup(group_map: *std.AutoHashMap(u32, protocol.SceneEntityGroupInfo), group_id: u32, allocator: std.mem.Allocator) !*protocol.SceneEntityGroupInfo {
        if (group_map.getPtr(group_id)) |existing_group| {
            return existing_group;
        }
        var new_group = protocol.SceneEntityGroupInfo.init(allocator);
        new_group.state = 1;
        new_group.group_id = group_id;
        try group_map.put(group_id, new_group);
        return group_map.getPtr(group_id).?;
    }
};
pub const ChallengeSceneManager = struct {
    allocator: std.mem.Allocator,
    pub fn init(allocator: std.mem.Allocator) ChallengeSceneManager {
        return ChallengeSceneManager{ .allocator = allocator };
    }
    pub fn createScene(
        self: *ChallengeSceneManager,
        avatar_list: ArrayList(u32),
        plane_id: u32,
        floor_id: u32,
        entry_id: u32,
        world_id: u32,
        monster_id: u32,
        event_id: u32,
        group_id: u32,
        maze_group_id: u32,
    ) !protocol.SceneInfo {
        const res_config = try Res_config.anchorLoader(self.allocator, "resources/res.json");
        var generator = UidGenerator().init();

        var scene_info = protocol.SceneInfo.init(self.allocator);
        scene_info.game_mode_type = 4;
        scene_info.plane_id = plane_id;
        scene_info.floor_id = floor_id;
        scene_info.entry_id = entry_id;
        scene_info.leader_entity_id = avatar_list.items[0];
        scene_info.world_id = world_id;
        try scene_info.group_state_list.append(protocol.SceneGroupState{
            .group_id = maze_group_id,
            .is_default = true,
        });
        { // Character
            var scene_group = protocol.SceneEntityGroupInfo.init(self.allocator);
            scene_group.state = 1;
            scene_group.group_id = 0;
            for (avatar_list.items) |avatarConf| {
                try scene_group.entity_list.append(.{
                    .inst_id = 1,
                    .entity_id = @intCast(avatarConf + 100000),
                    .entity = .{
                        .actor = .{
                            .base_avatar_id = avatarConf,
                            .avatar_type = .AVATAR_FORMAL_TYPE,
                            .uid = 1,
                            .map_layer = 0,
                        },
                    },
                    .motion = .{ .pos = .{}, .rot = .{} },
                });
            }
            try scene_info.entity_group_list.append(scene_group);
        }
        for (res_config.scene_config.items) |sceneConf| {
            if (sceneConf.planeID == scene_info.plane_id) {
                for (sceneConf.monsters.items) |monsConf| { //create monster
                    var scene_group = protocol.SceneEntityGroupInfo.init(self.allocator);
                    scene_group.state = 1;
                    if (monsConf.groupId == group_id) {
                        scene_group.group_id = group_id;

                        var monster_info = protocol.SceneNpcMonsterInfo.init(self.allocator);
                        monster_info.monster_id = monster_id;
                        monster_info.event_id = event_id;
                        monster_info.world_level = 6;

                        try scene_group.entity_list.append(.{
                            .entity = .{ .npc_monster = monster_info },
                            .group_id = group_id,
                            .inst_id = monsConf.instId,
                            .entity_id = generator.nextId(),
                            .motion = .{
                                .pos = .{ .x = monsConf.pos.x, .y = monsConf.pos.y, .z = monsConf.pos.z },
                                .rot = .{ .x = monsConf.rot.x, .y = monsConf.rot.y, .z = monsConf.rot.z },
                            },
                        });
                        try scene_info.entity_group_list.append(scene_group);
                    }
                }
            }
        }
        for (res_config.scene_config.items) |sceneConf| {
            if (sceneConf.planeID == scene_info.plane_id) {
                for (sceneConf.props.items) |propConf| { //create props
                    var scene_group = protocol.SceneEntityGroupInfo.init(self.allocator);
                    scene_group.state = 1;
                    scene_group.group_id = group_id;

                    var prop_info = protocol.ScenePropInfo.init(self.allocator);
                    prop_info.prop_id = propConf.propId;
                    prop_info.prop_state = propConf.propState;

                    try scene_group.entity_list.append(.{
                        .entity = .{ .prop = prop_info },
                        .group_id = group_id,
                        .inst_id = propConf.instId,
                        .entity_id = 0,
                        .motion = .{
                            .pos = .{ .x = propConf.pos.x, .y = propConf.pos.y, .z = propConf.pos.z },
                            .rot = .{ .x = propConf.rot.x, .y = propConf.rot.y, .z = propConf.rot.z },
                        },
                    });
                    try scene_info.entity_group_list.append(scene_group);
                }
            }
        }
        return scene_info;
    }
};

pub const MazeMapManager = struct {
    allocator: std.mem.Allocator,
    pub fn init(allocator: std.mem.Allocator) MazeMapManager {
        return MazeMapManager{ .allocator = allocator };
    }
    pub fn setMazeMapData(
        self: *MazeMapManager,
        map_info: *protocol.SceneMapInfo,
        floor_id: u32,
    ) !void {
        const config = try Config.loadMapEntranceConfig(self.allocator, "resources/MapEntrance.json");
        const res_config = try Res_config.anchorLoader(self.allocator, "resources/res.json");
        var plane_ids = ArrayList(u32).init(self.allocator);
        for (config.map_entrance_config.items) |entrConf| {
            if (entrConf.floor_id == floor_id) {
                try plane_ids.append(entrConf.plane_id);
            }
        }

        map_info.maze_group_list = ArrayList(protocol.MazeGroup).init(self.allocator);
        map_info.maze_prop_list = ArrayList(protocol.MazePropState).init(self.allocator);
        for (res_config.scene_config.items) |resConf| {
            for (plane_ids.items) |plane_id| {
                if (resConf.planeID == plane_id) {
                    for (resConf.props.items) |propConf| {
                        try map_info.maze_group_list.append(protocol.MazeGroup{
                            .NOBKEONAKLE = ArrayList(u32).init(self.allocator),
                            .group_id = propConf.groupId,
                        });
                        try map_info.maze_prop_list.append(protocol.MazePropState{
                            .group_id = propConf.groupId,
                            .config_id = propConf.instId,
                            .state = propConf.propState,
                        });
                    }
                }
            }
        }
    }
};
