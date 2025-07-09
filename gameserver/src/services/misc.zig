const std = @import("std");
const protocol = @import("protocol");
const Session = @import("../Session.zig");
const Packet = @import("../Packet.zig");

const Allocator = std.mem.Allocator;
const CmdID = protocol.CmdID;

pub fn onPlayerHeartBeat(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const req = try packet.getProto(protocol.PlayerHeartBeatCsReq, allocator);
    defer req.deinit();

    const encoded = "ICAgICAgICBsb2NhbCBmdW5jdGlvbiBzZXRUZXh0Q29tcG9uZW50KHBhdGgsIG5ld1RleHQpCiAgICAgICAgICAgIGxvY2FsIG9iaiA9IENTLlVuaXR5RW5naW5lLkdhbWVPYmplY3QuRmluZChwYXRoKQogICAgICAgICAgICBpZiBvYmogdGhlbgogICAgICAgICAgICAgICAgbG9jYWwgdGV4dENvbXBvbmVudCA9IG9iajpHZXRDb21wb25lbnRJbkNoaWxkcmVuKHR5cGVvZihDUy5SUEcuQ2xpZW50LkxvY2FsaXplZFRleHQpKQogICAgICAgICAgICAgICAgaWYgdGV4dENvbXBvbmVudCB0aGVuCiAgICAgICAgICAgICAgICAgICAgdGV4dENvbXBvbmVudC50ZXh0ID0gbmV3VGV4dAogICAgICAgICAgICAgICAgZW5kCiAgICAgICAgICAgIGVuZAogICAgICAgIGVuZAogICAgICAgIAogICAgICAgIHNldFRleHRDb21wb25lbnQoIlVJUm9vdC9BYm92ZURpYWxvZy9CZXRhSGludERpYWxvZyhDbG9uZSkiLCAiPGNvbG9yPSNkNmU4Yzg+6L+Z5piv5YWN6LS55qih5ouf5Zmo77yM5aaC5p6c5oKo6Iqx6ZKx6LSt5LmwPC9jb2xvcj4iKQogICAgICAgIHNldFRleHRDb21wb25lbnQoIlZlcnNpb25UZXh0IiwgIjxjb2xvcj0jZDZlOGM4Puivt+S4vuaKpemAgOasvjwvY29sb3I+Iik=";

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
