const std = @import("std");
const protocol = @import("protocol");
const Session = @import("Session.zig");
const Packet = @import("Packet.zig");

const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const CmdID = protocol.CmdID;

const value_command = @import("./commands/value.zig");
const help_command = @import("./commands/help.zig");
const tp_command = @import("./commands/tp.zig");
const unstuck_command = @import("./commands/unstuck.zig");
const sync_command = @import("./commands/sync.zig");
const refill_command = @import("./commands/refill.zig");

// 如果需要可以添加其他错误
const SystemErrors = error{ CommandError, SystemResources, Unexpected, AccessDenied, WouldBlock, ConnectionResetByPeer, OutOfMemory, DiskQuota, FileTooBig, InputOutput, NoSpaceLeft, DeviceBusy, InvalidArgument, BrokenPipe, OperationAborted };
const FileErrors = error{ NotOpenForWriting, LockViolation, Overflow, InvalidCharacter, ProcessFdQuotaExceeded, SystemFdQuotaExceeded, SymLinkLoop, NameTooLong, FileNotFound, NotDir, NoDevice, SharingViolation, PathAlreadyExists, PipeBusy, InvalidUtf8, InvalidWtf8, BadPathName, NetworkNotFound, AntivirusInterference, IsDir, FileLocksNotSupported, FileBusy };
const NetworkErrors = error{ ConnectionTimedOut, NotOpenForReading, SocketNotConnected, Unseekable, StreamTooLong };
const ParseErrors = error{ UnexpectedToken, InvalidNumber, InvalidEnumTag, DuplicateField, UnknownField, MissingField, LengthMismatch, SyntaxError, UnexpectedEndOfInput, BufferUnderrun, ValueTooLong, InsufficientTokens, InvalidFormat };
const MiscErrors = error{ PermissionDenied, NetworkSubsystemFailed, FileSystem, CurrentWorkingDirectoryUnlinked, InvalidBatchScriptArg, InvalidExe, ResourceLimitReached, InvalidUserId, InvalidName, InvalidHandle, WaitAbandoned, WaitTimeOut, StdoutStreamTooLong, StderrStreamTooLong };
pub const Error = SystemErrors || FileErrors || NetworkErrors || ParseErrors || MiscErrors;

const CommandFn = *const fn (session: *Session, args: []const u8, allocator: Allocator) Error!void;

const Command = struct {
    name: []const u8,
    action: []const u8,
    func: CommandFn,
};

const commandList = [_]Command{
    Command{ .name = "help", .action = "", .func = help_command.handle },
    Command{ .name = "test", .action = "", .func = value_command.handle },
    Command{ .name = "node", .action = "", .func = value_command.challengeNode },
    Command{ .name = "set", .action = "", .func = value_command.setGachaCommand },
    Command{ .name = "tp", .action = "", .func = tp_command.handle },
    Command{ .name = "unstuck", .action = "", .func = unstuck_command.handle },
    Command{ .name = "sync", .action = "", .func = sync_command.onGenerateAndSync },
    Command{ .name = "refill", .action = "", .func = refill_command.onRefill },
};

pub fn handleCommand(session: *Session, msg: []const u8, allocator: Allocator) Error!void {
    if (msg.len < 1 or msg[0] != '/') {
        std.debug.print("消息文本 2: {any}\n", .{msg});
        return sendMessage(session, "命令必须以 '/' 开头", allocator);
    }

    const input = msg[1..]; // 移除开头的 '/'
    var tokenizer = std.mem.tokenize(u8, input, " ");
    const command = tokenizer.next().?;
    const args = tokenizer.rest();

    for (commandList) |cmd| {
        if (std.mem.eql(u8, cmd.name, command)) {
            return try cmd.func(session, args, allocator);
        }
    }
    try sendMessage(session, "无效命令", allocator);
}

pub fn sendMessage(session: *Session, msg: []const u8, allocator: Allocator) Error!void {
    var chat = protocol.RevcMsgScNotify.init(allocator);
    chat.message_type = protocol.MsgType.MSG_TYPE_CUSTOM_TEXT;
    chat.chat_type = protocol.ChatType.CHAT_TYPE_PRIVATE;
    chat.source_uid = 2000;
    chat.message_text = .{ .Const = msg };
    chat.target_uid = 114514; // 接收者ID
    try session.send(CmdID.CmdRevcMsgScNotify, chat);
}
