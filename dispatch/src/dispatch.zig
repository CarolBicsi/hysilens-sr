const std = @import("std");
const httpz = @import("httpz");
const protocol = @import("protocol");
const HttpClient = @import("tls12");
const Base64Encoder = @import("std").base64.standard.Encoder;
const Base64Decoder = @import("std").base64.standard.Decoder;
const hotfixInfo = @import("hotfix.zig");
const CNPROD_HOST = "prod-gf-cn-dp01.bhsr.com";
const CNBETA_HOST = "beta-release01-cn.bhsr.com";
const OSPROD_HOST = "prod-official-asia-dp01.starrails.com";
const OSBETA_HOST = "beta-release01-asia.starrails.com";

pub fn onQueryDispatch(_: *httpz.Request, res: *httpz.Response) !void {
    std.log.debug("查询调度", .{});

    var proto = protocol.Dispatch.init(res.arena);

    const region_info = protocol.RegionInfo{
        .name = .{ .Const = "Ciallo～(∠・ω< )⌒☆" },
        .display_name = .{ .Const = "Ciallo～(∠・ω< )⌒☆" },
        .env_type = .{ .Const = "21" },
        .title = .{ .Const = "Ciallo～(∠・ω< )⌒☆" },
        .dispatch_url = .{ .Const = "http://127.0.0.1:21000/query_gateway" },
    };

    try proto.region_list.append(region_info);

    const data = try proto.encode(res.arena);
    const size = Base64Encoder.calcSize(data.len);
    const output = try res.arena.alloc(u8, size);
    _ = Base64Encoder.encode(output, data);

    res.body = output;
}

pub fn onQueryGateway(req: *httpz.Request, res: *httpz.Response) !void {
    std.log.debug("查询网关", .{});

    var proto = protocol.GateServer.init(res.arena);
    const query = try req.query();
    const version = query.get("version") orelse "";
    std.log.info("获取版本 >> {s}", .{version});
    const dispatch_seed = query.get("dispatch_seed") orelse "";
    std.log.info("获取调度种子 >> {s}", .{dispatch_seed});
    const host = selectHost(version);
    const gatewayUrl = constructUrl(host, version, dispatch_seed);
    std.log.info("构造的网关URL >> {s}", .{gatewayUrl});
    const hotfix = try hotfixInfo.Parser(res.arena, "hotfix.json", version);

    var assetBundleUrl: []const u8 = undefined;
    var exResourceUrl: []const u8 = undefined;
    var luaUrl: []const u8 = undefined;
    var iFixUrl: []const u8 = undefined;
    //var luaVersion: []const u8 = undefined;
    //var iFixVersion: []const u8 = undefined;

    //HTTP请求
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var client = HttpClient{ .allocator = allocator };
    defer client.deinit();
    try client.initDefaultProxies(allocator);

    const url = gatewayUrl;

    const uri = try std.Uri.parse(url);
    var server_header_buffer: [1024 * 1024]u8 = undefined;
    var gateway_request = try HttpClient.open(&client, .GET, uri, .{
        .server_header_buffer = &server_header_buffer,
        .redirect_behavior = @enumFromInt(10),
    });
    defer gateway_request.deinit();

    try gateway_request.send();
    try gateway_request.wait();
    const gateway_response_body = try gateway_request.reader().readAllAlloc(allocator, 16 * 1024 * 1024);

    //Base64解码
    const decoded_len = try Base64Decoder.calcSizeForSlice(gateway_response_body);
    const decoded_data = try allocator.alloc(u8, decoded_len);
    defer allocator.free(decoded_data);
    try Base64Decoder.decode(decoded_data, gateway_response_body);
    //网关服务器Protobuf解码
    const gateserver_proto = try protocol.GateServer.decode(decoded_data, res.arena);

    //std.log.info("\x1b[33;1m编码的网关响应 >> {s}\x1b[0m", .{gateway_response_body});
    //std.log.info("\x1b[32;1m解码的网关响应 >> {s}\x1b[0m", .{decoded_data});
    //std.log.info("\x1b[33;1mProtobuf消息 >> {}\x1b[0m", .{gateserver_proto});

    assetBundleUrl = hotfix.assetBundleUrl;
    exResourceUrl = hotfix.exResourceUrl;
    luaUrl = hotfix.luaUrl;
    iFixUrl = hotfix.iFixUrl;

    if (assetBundleUrl.len == 0 or exResourceUrl.len == 0 or luaUrl.len == 0 or iFixUrl.len == 0) {
        assetBundleUrl = gateserver_proto.asset_bundle_url.Owned.str;
        exResourceUrl = gateserver_proto.ex_resource_url.Owned.str;
        luaUrl = gateserver_proto.lua_url.Owned.str;
        iFixUrl = gateserver_proto.ifix_url.Owned.str;

        try hotfixInfo.putValue(version, assetBundleUrl, exResourceUrl, luaUrl, iFixUrl);
    }

    std.log.info("获取资源包URL >> {s}", .{assetBundleUrl});
    std.log.info("获取扩展资源URL >> {s}", .{exResourceUrl});
    std.log.info("获取Lua URL >> {s}", .{luaUrl});
    std.log.info("获取IFix URL >> {s}", .{iFixUrl});

    proto.retcode = 0;
    proto.port = 23301;
    proto.ip = .{ .Const = "127.0.0.1" };

    proto.asset_bundle_url = .{ .Const = assetBundleUrl };
    proto.ex_resource_url = .{ .Const = exResourceUrl };
    proto.lua_url = .{ .Const = luaUrl };

    proto.enable_watermark = true;
    proto.network_diagnostic = true;
    proto.enable_android_middle_package = true;
    proto.use_new_networking = true;
    proto.enable_design_data_version_update = true;
    proto.enable_version_update = true;
    proto.mtp_switch = true;
    proto.forbid_recharge = true;
    proto.close_redeem_code = true;
    proto.ECBFEHFPOFJ = false;
    proto.enable_save_replay_file = true;
    proto.ios_exam = true;
    proto.event_tracking_open = true;
    proto.use_tcp = true;
    proto.enable_upload_battle_log = false;

    const data = try proto.encode(res.arena);
    const size = Base64Encoder.calcSize(data.len);
    const output = try res.arena.alloc(u8, size);
    _ = Base64Encoder.encode(output, data);

    res.body = output;
}

pub fn selectHost(version: []const u8) []const u8 {
    if (std.mem.startsWith(u8, version, "CNPROD")) {
        return CNPROD_HOST;
    } else if (std.mem.startsWith(u8, version, "CNBETA")) {
        return CNBETA_HOST;
    } else if (std.mem.startsWith(u8, version, "OSPROD")) {
        return OSPROD_HOST;
    } else if (std.mem.startsWith(u8, version, "OSBETA")) {
        return OSBETA_HOST;
    } else {
        return "";
    }
}

pub fn constructUrl(host: []const u8, version: []const u8, dispatch_seed: []const u8) []const u8 {
    return std.fmt.allocPrint(std.heap.page_allocator, "https://{s}/query_gateway?version={s}&dispatch_seed={s}&language_type=1&platform_type=2&channel_id=1&sub_channel_id=1&is_need_url=1&account_type=1", .{ host, version, dispatch_seed }) catch "";
}
