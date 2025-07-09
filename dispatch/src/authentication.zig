const std = @import("std");
const httpz = @import("httpz");

pub fn onShieldLogin(req: *httpz.Request, res: *httpz.Response) !void {
    std.log.debug("Shield登录: {any}", .{req.body_len});
    //std.log.debug("Shield登录正文: {any}", .{req}); 会导致游戏崩溃

    try res.json(.{
        .data = .{
            .account = .{
                .area_code = "**",
                .email = "Ciallo～(∠・ω< )⌒☆",
                .country = "RU",
                .is_email_verify = "1",
                .token = "aa",
                .uid = "1337",
            },
            .device_grant_required = false,
            .reactivate_required = false,
            .realperson_required = false,
            .safe_mobilerequired = false,
        },
        .message = "OK",
        .retcode = 0,
    }, .{});
}

pub fn onShieldVerify(req: *httpz.Request, res: *httpz.Response) !void {
    std.log.debug("Shield验证: {any}", .{req.body_len});

    try res.json(.{
        .data = .{
            .account = .{
                .area_code = "**",
                .email = "Ciallo～(∠・ω< )⌒☆",
                .country = "RU",
                .is_email_verify = "1",
                .token = "aa",
                .uid = "1337",
            },
            .device_grant_required = false,
            .reactivate_required = false,
            .realperson_required = false,
            .safe_mobilerequired = false,
        },
        .message = "OK",
        .retcode = 0,
    }, .{});
}

pub fn onVerifyLogin(req: *httpz.Request, res: *httpz.Response) !void {
    std.log.debug("验证登录: {any}", .{req.body_len});

    var token: []const u8 = "aa";
    var uid: []const u8 = "1337";
    if (try req.jsonObject()) |t| {
        if (t.get("token")) |token_value| {
            token = token_value.string;
        }
        if (t.get("uid")) |uid_value| {
            uid = uid_value.string;
        }
    }

    try res.json(.{
        .retcode = 0,
        .message = "OK",
        .data = .{
            .account = .{
                .area_code = "**",
                .country = "CN",
                .is_email_verify = "1",
                .email = "Ciallo～(∠・ω< )⌒☆",
                .token = token,
                .uid = uid,
            },
        },
    }, .{});
}

pub fn onComboTokenReq(req: *httpz.Request, res: *httpz.Response) !void {
    std.log.debug("组合令牌请求: {any}", .{req.body_len});

    try res.json(.{
        .data = .{
            .account_type = 1,
            .open_id = "1337",
            .combo_id = "1337",
            .combo_token = "9065ad8507d5a1991cb6fddacac5999b780bbd92",
            .heartbeat = false,
            .data = "{\"guest\": false}",
        },
        .message = "OK",
        .retcode = 0,
    }, .{});
}

pub fn onRiskyApiCheck(req: *httpz.Request, res: *httpz.Response) !void {
    std.log.debug("风险API检查: {any}", .{req.body_len});

    try res.json(.{
        .retcode = 0,
        .message = "OK",
        .data = .{
            .id = "06611ed14c3131a676b19c0d34c0644b",
            .action = "ACTION_NONE",
            .geetest = null,
        },
    }, .{});
}

pub fn onGetConfig(_: *httpz.Request, res: *httpz.Response) !void {
    std.log.debug("获取配置: ", .{});

    try res.json(.{
        .retcode = 0,
        .message = "OK",
        .data = .{
            .protocol = true,
            .qr_enabled = false,
            .log_level = "INFO",
            .announce_url = "",
            .push_alias_type = 0,
            .disable_ysdk_guard = true,
            .enable_announce_pic_popup = false,
            .app_name = "崩�??RPG",
            .qr_enabled_apps = .{
                .bbs = false,
                .cloud = false,
            },
            .qr_app_icons = .{
                .app = "",
                .bbs = "",
                .cloud = "",
            },
            .qr_cloud_display_name = "",
            .enable_user_center = true,
            .functional_switch_configs = .{},
        },
    }, .{});
}

pub fn onLoadConfig(_: *httpz.Request, res: *httpz.Response) !void {
    std.log.debug("加载配置: ", .{});

    try res.json(.{
        .retcode = 0,
        .message = "OK",
        .data = .{
            .id = 24,
            .game_key = "hkrpg_global",
            .client = "PC",
            .identity = "I_IDENTITY",
            .guest = false,
            .ignore_versions = "",
            .scene = "S_NORMAL",
            .name = "崩�??RPG",
            .disable_regist = false,
            .enable_email_captcha = false,
            .thirdparty = .{ "fb", "tw", "gl", "ap" },
            .disable_mmt = false,
            .server_guest = false,
            .thirdparty_ignore = .{},
            .enable_ps_bind_account = false,
            .thirdparty_login_configs = .{
                .tw = .{
                    .token_type = "TK_GAME_TOKEN",
                    .game_token_expires_in = 2592000,
                },
                .ap = .{
                    .token_type = "TK_GAME_TOKEN",
                    .game_token_expires_in = 604800,
                },
                .fb = .{
                    .token_type = "TK_GAME_TOKEN",
                    .game_token_expires_in = 2592000,
                },
                .gl = .{
                    .token_type = "TK_GAME_TOKEN",
                    .game_token_expires_in = 604800,
                },
            },
            .initialize_firebase = false,
            .bbs_auth_login = false,
            .bbs_auth_login_ignore = {},
            .fetch_instance_id = false,
            .enable_flash_login = false,
        },
    }, .{});
}

pub fn onappLoginByPassword(req: *httpz.Request, res: *httpz.Response) !void {
    std.log.debug("密码登录: {any}", .{req.body_len});

    try res.json(.{
        .retcode = 0,
        .message = "OK",
        .data = .{
            .bind_email_action_ticket = "",
            .ext_user_info = .{
                .birth = "0",
                .guardian_email = "",
            },
            .reactivate_action_token = "",
            .token = .{
                .token = "aa",
                .token_type = "1",
            },
            .user_info = .{
                .account_name = "Ciallo～(∠・ω< )⌒☆",
                .aid = "1337",
                .area_code = "**",
                .country = "RU",
                .email = "Ciallo～(∠・ω< )⌒☆",
                .is_email_verify = "1",
            },
        },
    }, .{});
}
