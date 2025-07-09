const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const std = @import("std");

pub const BattleConfig = struct {
    battle_id: u32,
    stage_id: u32,
    cycle_count: u32,
    monster_wave: ArrayList(ArrayList(u32)),
    monster_level: u32,
    blessings: ArrayList(u32),
};
pub const Stage = struct {
    level: u32,
    stage_id: u32,
    monster_list: ArrayList(ArrayList(u32)),
};
const ExtraMazeBuff = struct {
    enable: bool,
    mazebuff: ArrayList(u32),
};

const Lightcone = struct {
    id: u32,
    rank: u32,
    level: u32,
    promotion: u32,
};

pub const Relic = struct {
    id: u32,
    level: u32,
    main_affix_id: u32,
    sub_count: u32,
    stat1: u32,
    cnt1: u32,
    step1: u32,
    stat2: u32,
    cnt2: u32,
    step2: u32,
    stat3: u32,
    cnt3: u32,
    step3: u32,
    stat4: u32,
    cnt4: u32,
    step4: u32,
};

pub const Avatar = struct {
    id: u32,
    hp: u32,
    sp: u32,
    level: u32,
    promotion: u32,
    rank: u32,
    lightcone: Lightcone,
    relics: ArrayList(Relic),
    use_technique: bool,
};
const PlayerIcon = struct {
    id: u32,
};
const MainMission = struct {
    main_mission_id: u32,
};
const TutorialGuide = struct {
    guide_group_id: u32,
};
const Tutorial = struct {
    tutorial_id: u32,
};
const Activity = struct {
    activity_module_list: ArrayList(u32),
    panel_id: u32,
};
const ChallengeConfig = struct {
    id: u32,
    npc_monster_id_list1: ArrayList(u32),
    npc_monster_id_list2: ArrayList(u32),
    event_id_list1: ArrayList(u32),
    event_id_list2: ArrayList(u32),
    map_entrance_id: u32,
    map_entrance_id2: u32,
    maze_group_id1: u32,
    maze_group_id2: ?u32, // to check if it missing MazeGroupID2 field
    maze_buff_id: u32,
};

const MapEntrance = struct {
    floor_id: u32,
    id: u32,
    plane_id: u32,
    begin_main_mission_idlist: ArrayList(u32),
    finish_main_mission_idlist: ArrayList(u32),
    finish_sub_mission_idlist: ArrayList(u32),
};
const MazePlane = struct {
    floor_id_list: ArrayList(u32),
    start_floor_id: u32,
    challenge_plane_id: u32,
    world_id: u32,
};
pub const GameConfig = struct {
    battle_config: BattleConfig,
    avatar_config: ArrayList(Avatar),
};
pub const StageConfig = struct {
    stage_config: ArrayList(Stage),
};
pub const PlayerIconConfig = struct {
    player_icon_config: ArrayList(PlayerIcon),
};
pub const MainMissionConfig = struct {
    main_mission_config: ArrayList(MainMission),
};
pub const TutorialGuideConfig = struct {
    tutorial_guide_config: ArrayList(TutorialGuide),
};
pub const TutorialConfig = struct {
    tutorial_config: ArrayList(Tutorial),
};
pub const ActivityConfig = struct {
    activity_config: ArrayList(Activity),
};
pub const ChallengeMazeConfig = struct {
    challenge_config: ArrayList(ChallengeConfig),
};
pub const MapEntranceConfig = struct {
    map_entrance_config: ArrayList(MapEntrance),
};
pub const MazePlaneConfig = struct {
    maze_plane_config: ArrayList(MazePlane),
};
const ErrorSet = error{ CommandError, SystemResources, Unexpected, AccessDenied, WouldBlock, ConnectionResetByPeer, OutOfMemory, DiskQuota, FileTooBig, InputOutput, NoSpaceLeft, DeviceBusy, InvalidArgument, BrokenPipe, OperationAborted, NotOpenForWriting, LockViolation, Overflow, InvalidCharacter, ProcessFdQuotaExceeded, SystemFdQuotaExceeded, SymLinkLoop, NameTooLong, FileNotFound, NotDir, NoDevice, SharingViolation, PathAlreadyExists, PipeBusy, InvalidUtf8, InvalidWtf8, BadPathName, NetworkNotFound, AntivirusInterference, IsDir, FileLocksNotSupported, FileBusy, ConnectionTimedOut, NotOpenForReading, SocketNotConnected, Unseekable, UnexpectedToken, InvalidNumber, InvalidEnumTag, DuplicateField, UnknownField, MissingField, LengthMismatch, SyntaxError, UnexpectedEndOfInput, BufferUnderrun, ValueTooLong, InsufficientTokens, InvalidFormat };

pub fn loadConfig(
    comptime ConfigType: type,
    comptime parseFn: fn (std.json.Value, Allocator) ErrorSet!ConfigType,
    allocator: Allocator,
    filename: []const u8,
) ErrorSet!ConfigType {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    const file_size = try file.getEndPos();
    const buffer = try file.readToEndAlloc(allocator, file_size);
    defer allocator.free(buffer);

    var json_tree = try std.json.parseFromSlice(std.json.Value, allocator, buffer, .{});
    defer json_tree.deinit();

    const root = json_tree.value;
    return try parseFn(root, allocator);
}

// Specialized loaders
pub fn loadGameConfig(allocator: Allocator, filename: []const u8) ErrorSet!GameConfig {
    return loadConfig(GameConfig, parseConfig, allocator, filename);
}

pub fn loadStageConfig(allocator: Allocator, filename: []const u8) ErrorSet!StageConfig {
    return loadConfig(StageConfig, parseStageConfig, allocator, filename);
}

pub fn loadPlayerIconConfig(allocator: Allocator, filename: []const u8) ErrorSet!PlayerIconConfig {
    return loadConfig(PlayerIconConfig, parsePlayerIconConfig, allocator, filename);
}

pub fn loadMainMissionConfig(allocator: Allocator, filename: []const u8) ErrorSet!MainMissionConfig {
    return loadConfig(MainMissionConfig, parseMainMissionConfig, allocator, filename);
}

pub fn loadTutorialGuideConfig(allocator: Allocator, filename: []const u8) ErrorSet!TutorialGuideConfig {
    return loadConfig(TutorialGuideConfig, parseTutorialGuideConfig, allocator, filename);
}

pub fn loadTutorialConfig(allocator: Allocator, filename: []const u8) ErrorSet!TutorialConfig {
    return loadConfig(TutorialConfig, parseTutorialConfig, allocator, filename);
}

pub fn loadActivityConfig(allocator: Allocator, filename: []const u8) ErrorSet!ActivityConfig {
    return loadConfig(ActivityConfig, parseActivityConfig, allocator, filename);
}

pub fn loadChallengeConfig(allocator: Allocator, filename: []const u8) ErrorSet!ChallengeMazeConfig {
    return loadConfig(ChallengeMazeConfig, parseChallengeConfig, allocator, filename);
}

pub fn loadMapEntranceConfig(allocator: Allocator, filename: []const u8) ErrorSet!MapEntranceConfig {
    return loadConfig(MapEntranceConfig, parseMapEntranceConfig, allocator, filename);
}

pub fn loadMazePlaneConfig(allocator: Allocator, filename: []const u8) ErrorSet!MazePlaneConfig {
    return loadConfig(MazePlaneConfig, parseMazePlaneConfig, allocator, filename);
}

pub fn parseConfig(root: std.json.Value, allocator: Allocator) ErrorSet!GameConfig {
    const battle_config_json = root.object.get("battle_config").?;
    var battle_config = BattleConfig{
        .battle_id = @intCast(battle_config_json.object.get("battle_id").?.integer),
        .stage_id = @intCast(battle_config_json.object.get("stage_id").?.integer),
        .cycle_count = @intCast(battle_config_json.object.get("cycle_count").?.integer),
        .monster_wave = ArrayList(ArrayList(u32)).init(allocator),
        .monster_level = @intCast(battle_config_json.object.get("monster_level").?.integer),
        .blessings = ArrayList(u32).init(allocator),
    };

    for (battle_config_json.object.get("monster_wave").?.array.items) |wave| {
        var wave_list = ArrayList(u32).init(allocator);
        for (wave.array.items) |monster| {
            try wave_list.append(@intCast(monster.integer));
        }
        try battle_config.monster_wave.append(wave_list);
    }
    for (battle_config_json.object.get("blessings").?.array.items) |blessing| {
        try battle_config.blessings.append(@intCast(blessing.integer));
    }

    var avatar_config = ArrayList(Avatar).init(allocator);
    for (root.object.get("avatar_config").?.array.items) |avatar_json| {
        var avatar = Avatar{
            .id = @intCast(avatar_json.object.get("id").?.integer),
            .hp = @intCast(avatar_json.object.get("hp").?.integer),
            .sp = @intCast(avatar_json.object.get("sp").?.integer),
            .level = @intCast(avatar_json.object.get("level").?.integer),
            .promotion = @intCast(avatar_json.object.get("promotion").?.integer),
            .rank = @intCast(avatar_json.object.get("rank").?.integer),
            .lightcone = undefined,
            .relics = ArrayList(Relic).init(allocator),
            .use_technique = avatar_json.object.get("use_technique").?.bool,
        };

        const lightcone_json = avatar_json.object.get("lightcone").?;
        avatar.lightcone = Lightcone{
            .id = @intCast(lightcone_json.object.get("id").?.integer),
            .rank = @intCast(lightcone_json.object.get("rank").?.integer),
            .level = @intCast(lightcone_json.object.get("level").?.integer),
            .promotion = @intCast(lightcone_json.object.get("promotion").?.integer),
        };

        for (avatar_json.object.get("relics").?.array.items) |relic_str| {
            const relic = try parseRelic(relic_str.string, allocator);
            try avatar.relics.append(relic);
        }

        try avatar_config.append(avatar);
    }

    return GameConfig{
        .battle_config = battle_config,
        .avatar_config = avatar_config,
    };
}
pub fn parseStageConfig(root: std.json.Value, allocator: Allocator) ErrorSet!StageConfig {
    var stage_config = ArrayList(Stage).init(allocator);
    for (root.object.get("stage_config").?.array.items) |stage_json| {
        var stage = Stage{
            .level = @intCast(stage_json.object.get("Level").?.integer),
            .stage_id = @intCast(stage_json.object.get("StageID").?.integer),
            .monster_list = ArrayList(ArrayList(u32)).init(allocator),
        };

        for (stage_json.object.get("MonsterList").?.array.items) |wave| {
            var wave_list = ArrayList(u32).init(allocator);
            for (wave.array.items) |monster| {
                try wave_list.append(@intCast(monster.integer));
            }
            try stage.monster_list.append(wave_list);
        }

        try stage_config.append(stage);
    }

    return StageConfig{
        .stage_config = stage_config,
    };
}
fn parsePlayerIconConfig(root: std.json.Value, allocator: Allocator) ErrorSet!PlayerIconConfig {
    var player_icon_config = ArrayList(PlayerIcon).init(allocator);
    for (root.object.get("player_icon_config").?.array.items) |icon_json| {
        const icon = PlayerIcon{
            .id = @intCast(icon_json.object.get("ID").?.integer),
        };
        try player_icon_config.append(icon);
    }
    return PlayerIconConfig{
        .player_icon_config = player_icon_config,
    };
}
fn parseMainMissionConfig(root: std.json.Value, allocator: Allocator) ErrorSet!MainMissionConfig {
    var main_mission_config = ArrayList(MainMission).init(allocator);
    for (root.object.get("main_mission_config").?.array.items) |main_json| {
        const main_mission = MainMission{
            .main_mission_id = @intCast(main_json.object.get("MainMissionID").?.integer),
        };
        try main_mission_config.append(main_mission);
    }
    return MainMissionConfig{
        .main_mission_config = main_mission_config,
    };
}
fn parseTutorialGuideConfig(root: std.json.Value, allocator: Allocator) ErrorSet!TutorialGuideConfig {
    var tutorial_guide_config = ArrayList(TutorialGuide).init(allocator);
    for (root.object.get("tutorial_guide_config").?.array.items) |guide_json| {
        const tutorial_guide = TutorialGuide{
            .guide_group_id = @intCast(guide_json.object.get("GroupID").?.integer),
        };
        try tutorial_guide_config.append(tutorial_guide);
    }
    return TutorialGuideConfig{
        .tutorial_guide_config = tutorial_guide_config,
    };
}
fn parseTutorialConfig(root: std.json.Value, allocator: Allocator) ErrorSet!TutorialConfig {
    var tutorial_config = ArrayList(Tutorial).init(allocator);
    for (root.object.get("tutorial_config").?.array.items) |tutorial_json| {
        const tutorial = Tutorial{
            .tutorial_id = @intCast(tutorial_json.object.get("TutorialID").?.integer),
        };
        try tutorial_config.append(tutorial);
    }
    return TutorialConfig{
        .tutorial_config = tutorial_config,
    };
}
fn parseActivityConfig(root: std.json.Value, allocator: Allocator) ErrorSet!ActivityConfig {
    var activity_config = ArrayList(Activity).init(allocator);
    for (root.object.get("activity_config").?.array.items) |activity_json| {
        var activity = Activity{
            .panel_id = @intCast(activity_json.object.get("ActivityID").?.integer),
            .activity_module_list = ArrayList(u32).init(allocator),
        };
        for (activity_json.object.get("ActivityModuleIDList").?.array.items) |id| {
            try activity.activity_module_list.append(@intCast(id.integer));
        }
        try activity_config.append(activity);
    }
    return ActivityConfig{
        .activity_config = activity_config,
    };
}
fn parseChallengeConfig(root: std.json.Value, allocator: Allocator) ErrorSet!ChallengeMazeConfig {
    var challenge_config = ArrayList(ChallengeConfig).init(allocator);
    for (root.object.get("challenge_config").?.array.items) |challenge_json| {
        var challenge = ChallengeConfig{
            .id = @intCast(challenge_json.object.get("ID").?.integer),
            .maze_buff_id = @intCast(challenge_json.object.get("MazeBuffID").?.integer),
            .npc_monster_id_list1 = ArrayList(u32).init(allocator),
            .npc_monster_id_list2 = ArrayList(u32).init(allocator),
            .event_id_list1 = ArrayList(u32).init(allocator),
            .event_id_list2 = ArrayList(u32).init(allocator),
            .map_entrance_id = @intCast(challenge_json.object.get("MapEntranceID").?.integer),
            .map_entrance_id2 = @intCast(challenge_json.object.get("MapEntranceID2").?.integer),
            .maze_group_id1 = @intCast(challenge_json.object.get("MazeGroupID1").?.integer),
            .maze_group_id2 = if (challenge_json.object.get("MazeGroupID2")) |val| @intCast(val.integer) else null,
        };
        for (challenge_json.object.get("NpcMonsterIDList1").?.array.items) |npc1| {
            try challenge.npc_monster_id_list1.append(@intCast(npc1.integer));
        }
        for (challenge_json.object.get("NpcMonsterIDList2").?.array.items) |npc2| {
            try challenge.npc_monster_id_list2.append(@intCast(npc2.integer));
        }
        for (challenge_json.object.get("EventIDList1").?.array.items) |event1| {
            try challenge.event_id_list1.append(@intCast(event1.integer));
        }
        for (challenge_json.object.get("EventIDList2").?.array.items) |event2| {
            try challenge.event_id_list2.append(@intCast(event2.integer));
        }
        try challenge_config.append(challenge);
    }

    return ChallengeMazeConfig{
        .challenge_config = challenge_config,
    };
}
fn parseMapEntranceConfig(root: std.json.Value, allocator: Allocator) ErrorSet!MapEntranceConfig {
    var map_entrance_config = ArrayList(MapEntrance).init(allocator);
    for (root.object.get("map_entrance_config").?.array.items) |mapEntrance| {
        var entrance = MapEntrance{
            .id = @intCast(mapEntrance.object.get("ID").?.integer),
            .floor_id = @intCast(mapEntrance.object.get("FloorID").?.integer),
            .plane_id = @intCast(mapEntrance.object.get("PlaneID").?.integer),
            .begin_main_mission_idlist = ArrayList(u32).init(allocator),
            .finish_main_mission_idlist = ArrayList(u32).init(allocator),
            .finish_sub_mission_idlist = ArrayList(u32).init(allocator),
        };
        for (mapEntrance.object.get("BeginMainMissionList").?.array.items) |id| {
            try entrance.begin_main_mission_idlist.append(@intCast(id.integer));
        }
        for (mapEntrance.object.get("FinishMainMissionList").?.array.items) |id| {
            try entrance.finish_main_mission_idlist.append(@intCast(id.integer));
        }
        for (mapEntrance.object.get("FinishSubMissionList").?.array.items) |id| {
            try entrance.finish_sub_mission_idlist.append(@intCast(id.integer));
        }
        try map_entrance_config.append(entrance);
    }

    return MapEntranceConfig{
        .map_entrance_config = map_entrance_config,
    };
}
fn parseMazePlaneConfig(root: std.json.Value, allocator: Allocator) ErrorSet!MazePlaneConfig {
    var maze_plane_config = ArrayList(MazePlane).init(allocator);
    for (root.object.get("maze_plane_config").?.array.items) |id| {
        var maze = MazePlane{
            .start_floor_id = @intCast(id.object.get("StartFloorID").?.integer),
            .challenge_plane_id = @intCast(id.object.get("PlaneID").?.integer),
            .world_id = @intCast(id.object.get("WorldID").?.integer),
            .floor_id_list = ArrayList(u32).init(allocator),
        };
        for (id.object.get("FloorIDList").?.array.items) |list| {
            try maze.floor_id_list.append(@intCast(list.integer));
        }
        try maze_plane_config.append(maze);
    }

    return MazePlaneConfig{
        .maze_plane_config = maze_plane_config,
    };
}
fn parseRelic(relic_str: []const u8, allocator: Allocator) !Relic {
    var tokens = ArrayList([]const u8).init(allocator);
    defer tokens.deinit();

    var iterator = std.mem.tokenize(u8, relic_str, ",");

    while (iterator.next()) |token| {
        try tokens.append(token);
    }

    const tokens_slice = tokens.items;

    if (tokens_slice.len < 5) {
        std.debug.print("relic parsing critical error (too few fields): {s}\n", .{relic_str});
        return error.InsufficientTokens;
    }

    const stat1 = try parseStatCount(tokens_slice[4]);
    const stat2 = if (tokens_slice.len > 5) try parseStatCount(tokens_slice[5]) else StatCount{ .stat = 0, .count = 0, .step = 0 };
    const stat3 = if (tokens_slice.len > 6) try parseStatCount(tokens_slice[6]) else StatCount{ .stat = 0, .count = 0, .step = 0 };
    const stat4 = if (tokens_slice.len > 7) try parseStatCount(tokens_slice[7]) else StatCount{ .stat = 0, .count = 0, .step = 0 };

    const relic = Relic{
        .id = try std.fmt.parseInt(u32, tokens_slice[0], 10),
        .level = try std.fmt.parseInt(u32, tokens_slice[1], 10),
        .main_affix_id = try std.fmt.parseInt(u32, tokens_slice[2], 10),
        .sub_count = try std.fmt.parseInt(u32, tokens_slice[3], 10),
        .stat1 = stat1.stat,
        .cnt1 = stat1.count,
        .step1 = stat1.step,
        .stat2 = stat2.stat,
        .cnt2 = stat2.count,
        .step2 = stat2.step,
        .stat3 = stat3.stat,
        .cnt3 = stat3.count,
        .step3 = stat3.step,
        .stat4 = stat4.stat,
        .cnt4 = stat4.count,
        .step4 = stat4.step,
    };

    return relic;
}

const StatCount = struct {
    stat: u32,
    count: u32,
    step: u32,
};

fn parseStatCount(token: []const u8) !StatCount {
    if (std.mem.indexOfScalar(u8, token, ':')) |first_colon| {
        if (std.mem.indexOfScalar(u8, token[first_colon + 1 ..], ':')) |second_colon_offset| {
            const second_colon = first_colon + 1 + second_colon_offset;
            const stat = try std.fmt.parseInt(u32, token[0..first_colon], 10);
            const count = try std.fmt.parseInt(u32, token[first_colon + 1 .. second_colon], 10);
            const step = try std.fmt.parseInt(u32, token[second_colon + 1 ..], 10);
            return StatCount{ .stat = stat, .count = count, .step = step };
        } else {
            return error.InvalidFormat;
        }
    } else {
        return error.InvalidFormat;
    }
}
