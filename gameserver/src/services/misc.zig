const std = @import("std");
const protocol = @import("protocol");
const Session = @import("../Session.zig");
const Packet = @import("../Packet.zig");

const Allocator = std.mem.Allocator;
const CmdID = protocol.CmdID;

pub fn onPlayerHeartBeat(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const req = try packet.getProto(protocol.PlayerHeartBeatCsReq, allocator);
    defer req.deinit();

    const encoded = "ICAgICAgICBsb2NhbCBmdW5jdGlvbiBzZXRUZXh0Q29tcG9uZW50KHBhdGgsIG5ld1RleHQpDQogICAgICAgICAgICBsb2NhbCBvYmogPSBDUy5Vbml0eUVuZ2luZS5HYW1lT2JqZWN0LkZpbmQocGF0aCkNCiAgICAgICAgICAgIGlmIG9iaiB0aGVuDQogICAgICAgICAgICAgICAgbG9jYWwgdGV4dENvbXBvbmVudCA9IG9iajpHZXRDb21wb25lbnRJbkNoaWxkcmVuKHR5cGVvZihDUy5SUEcuQ2xpZW50LkxvY2FsaXplZFRleHQpKQ0KICAgICAgICAgICAgICAgIGlmIHRleHRDb21wb25lbnQgdGhlbg0KICAgICAgICAgICAgICAgICAgICB0ZXh0Q29tcG9uZW50LnRleHQgPSBuZXdUZXh0DQogICAgICAgICAgICAgICAgZW5kDQogICAgICAgICAgICBlbmQNCiAgICAgICAgZW5kDQogICAgICAgIA0KICAgICAgICBzZXRUZXh0Q29tcG9uZW50KCJVSVJvb3QvQWJvdmVEaWFsb2cvQmV0YUhpbnREaWFsb2coQ2xvbmUpIiwgIjxjb2xvcj0jMDNmNGZjPkh5c2lsZW5zU1IgaXMgYSBmcmVlIGFuZCBvcGVuIHNvdXJjZSBzb2Z0d2FyZS48L2NvbG9yPiIpDQogICAgICAgIHNldFRleHRDb21wb25lbnQoIlZlcnNpb25UZXh0IiwgIjxjb2xvcj0jMDNmNGZjPlZpc2l0IGRpc2NvcmQuZ2cvcmV2ZXJzZWRyb29tcyBmb3IgbW9yZSBpbmZvITwvY29sb3I+IikNCg==";

    const dest_buf = try allocator.alloc(u8, try std.base64.standard.Decoder.calcSizeForSlice(encoded));
    try std.base64.standard.Decoder.decode(dest_buf, encoded);

    const managed_str = protocol.ManagedString.move(dest_buf, allocator);
    const download_data = protocol.ClientDownloadData{
        .version = 51,
        .time = @intCast(std.time.milliTimestamp()),
        .data = managed_str,
    };

    try session.send(CmdID.CmdPlayerHeartBeatScRsp, protocol.PlayerHeartBeatScRsp{
        .retcode = 0,
        .client_time_ms = req.client_time_ms,
        .server_time_ms = @intCast(std.time.milliTimestamp()),
        .download_data = download_data,
    });
}
