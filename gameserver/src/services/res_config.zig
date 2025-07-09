const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const std = @import("std");

const ResConfig = struct {
    planeID: u32,
    props: ArrayList(Props),
    monsters: ArrayList(Monsters),
    teleports: ArrayList(Teleports),
};
const Vector = struct {
    x: i32,
    y: i32,
    z: i32,
};
const Teleports = struct {
    anchorId: u32,
    groupId: u32,
    instId: u32,
    pos: Vector,
    rot: Vector,
    teleportId: u32,
};
const Monsters = struct {
    groupId: u32,
    instId: u32,
    eventId: u32,
    pos: Vector,
    rot: Vector,
    monsterId: u32,
};
const Props = struct {
    groupId: u32,
    instId: u32,
    propState: u32,
    pos: Vector,
    rot: Vector,
    propId: u32,
};
pub const SceneConfig = struct {
    scene_config: ArrayList(ResConfig),
};

pub fn anchorLoader(allocator: Allocator, filename: []const u8) !SceneConfig {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    const file_size = try file.getEndPos();
    const buffer = try file.readToEndAlloc(allocator, file_size);
    defer allocator.free(buffer);

    var json_tree = try std.json.parseFromSlice(std.json.Value, allocator, buffer, .{});
    defer json_tree.deinit();

    const root = json_tree.value;
    const config: SceneConfig = try parseAnchor(root, allocator);

    return config;
}

fn parseAnchor(root: anytype, allocator: Allocator) !SceneConfig {
    var res_config = ArrayList(ResConfig).init(allocator);
    for (root.object.get("scene_config").?.array.items) |res_json| {
        var res = ResConfig{
            .planeID = @intCast(res_json.object.get("planeID").?.integer),
            .props = ArrayList(Props).init(allocator),
            .monsters = ArrayList(Monsters).init(allocator),
            .teleports = ArrayList(Teleports).init(allocator),
        };
        for (res_json.object.get("props").?.array.items) |scene_prop| {
            var prop = Props{
                .groupId = @intCast(scene_prop.object.get("groupId").?.integer),
                .instId = @intCast(scene_prop.object.get("instId").?.integer),
                .propState = @intCast(scene_prop.object.get("propState").?.integer),
                .pos = undefined,
                .rot = undefined,
                .propId = @intCast(scene_prop.object.get("propId").?.integer),
            };
            const pos_json = scene_prop.object.get("pos").?;
            prop.pos = Vector{
                .x = @intCast(pos_json.object.get("x").?.integer),
                .y = @intCast(pos_json.object.get("y").?.integer),
                .z = @intCast(pos_json.object.get("z").?.integer),
            };
            const rot_json = scene_prop.object.get("rot").?;
            prop.rot = Vector{
                .x = @intCast(rot_json.object.get("x").?.integer),
                .y = @intCast(rot_json.object.get("y").?.integer),
                .z = @intCast(rot_json.object.get("z").?.integer),
            };
            try res.props.append(prop);
        }
        for (res_json.object.get("monsters").?.array.items) |monster_json| {
            var monster = Monsters{
                .groupId = @intCast(monster_json.object.get("groupId").?.integer),
                .instId = @intCast(monster_json.object.get("instId").?.integer),
                .eventId = @intCast(monster_json.object.get("eventId").?.integer),
                .monsterId = @intCast(monster_json.object.get("monsterId").?.integer),
                .pos = undefined,
                .rot = undefined,
            };
            const pos_json = monster_json.object.get("pos").?;
            monster.pos = Vector{
                .x = @intCast(pos_json.object.get("x").?.integer),
                .y = @intCast(pos_json.object.get("y").?.integer),
                .z = @intCast(pos_json.object.get("z").?.integer),
            };
            const rot_json = monster_json.object.get("rot").?;
            monster.rot = Vector{
                .x = @intCast(rot_json.object.get("x").?.integer),
                .y = @intCast(rot_json.object.get("y").?.integer),
                .z = @intCast(rot_json.object.get("z").?.integer),
            };
            try res.monsters.append(monster);
        }
        for (res_json.object.get("teleports").?.array.items) |teleport_json| {
            var teleport = Teleports{
                .anchorId = @intCast(teleport_json.object.get("anchorId").?.integer),
                .groupId = @intCast(teleport_json.object.get("groupId").?.integer),
                .instId = @intCast(teleport_json.object.get("instId").?.integer),
                .teleportId = @intCast(teleport_json.object.get("teleportId").?.integer),
                .pos = undefined,
                .rot = undefined,
            };
            const pos_json = teleport_json.object.get("pos").?;
            teleport.pos = Vector{
                .x = @intCast(pos_json.object.get("x").?.integer),
                .y = @intCast(pos_json.object.get("y").?.integer),
                .z = @intCast(pos_json.object.get("z").?.integer),
            };
            const rot_json = teleport_json.object.get("rot").?;
            teleport.rot = Vector{
                .x = @intCast(rot_json.object.get("x").?.integer),
                .y = @intCast(rot_json.object.get("y").?.integer),
                .z = @intCast(rot_json.object.get("z").?.integer),
            };
            try res.teleports.append(teleport);
        }
        try res_config.append(res);
    }

    return SceneConfig{
        .scene_config = res_config,
    };
}
