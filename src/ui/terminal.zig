//! Terminal control module
//! Raw mode, screen sizing, and ANSI control

const std = @import("std");
const posix = std.posix;

pub const Size = struct {
    width: u16,
    height: u16,
};

pub const Terminal = struct {
    original_termios: ?posix.termios,
    tty: std.fs.File,

    pub fn init() !Terminal {
        const tty = std.fs.cwd().openFile("/dev/tty", .{ .mode = .read_write }) catch {
            return Terminal{
                .original_termios = null,
                .tty = .{ .handle = posix.STDOUT_FILENO },
            };
        };

        return Terminal{
            .original_termios = null,
            .tty = tty,
        };
    }

    pub fn deinit(self: *Terminal) void {
        self.disableRawMode();
        if (self.original_termios != null) {
            self.tty.close();
        }
    }

    pub fn enableRawMode(self: *Terminal) !void {
        const termios = posix.tcgetattr(self.tty.handle) catch return;
        self.original_termios = termios;

        var raw = termios;

        raw.lflag = raw.lflag.difference(.{ .ECHO = true, .ICANON = true, .ISIG = true, .IEXTEN = true });
        raw.iflag = raw.iflag.difference(.{ .IXON = true, .ICRNL = true, .BRKINT = true, .INPCK = true, .ISTRIP = true });
        raw.oflag = raw.oflag.difference(.{ .OPOST = true });
        raw.cflag.CS8 = true;

        raw.cc[@intFromEnum(posix.V.MIN)] = 0;
        raw.cc[@intFromEnum(posix.V.TIME)] = 1;

        posix.tcsetattr(self.tty.handle, .FLUSH, raw) catch return;
    }

    pub fn disableRawMode(self: *Terminal) void {
        if (self.original_termios) |original| {
            posix.tcsetattr(self.tty.handle, .FLUSH, original) catch {};
            self.original_termios = null;
        }
    }

    pub fn getSize(self: *Terminal) Size {
        var wsz: posix.winsize = undefined;
        const result = posix.system.ioctl(self.tty.handle, posix.T.IOCGWINSZ, @intFromPtr(&wsz));
        if (result == 0) {
            return Size{
                .width = wsz.col,
                .height = wsz.row,
            };
        }
        return Size{ .width = 80, .height = 24 };
    }

    pub fn write(self: *Terminal, data: []const u8) void {
        self.tty.writeAll(data) catch {};
    }

    pub fn readKey(self: *Terminal) ?u8 {
        var buf: [1]u8 = undefined;
        const n = self.tty.read(&buf) catch return null;
        if (n == 0) return null;
        return buf[0];
    }

    pub fn readEscapeSequence(self: *Terminal) ?[3]u8 {
        var seq: [3]u8 = undefined;

        const n1 = self.tty.read(seq[0..1]) catch return null;
        if (n1 == 0) return null;

        if (seq[0] == '[') {
            const n2 = self.tty.read(seq[1..2]) catch return null;
            if (n2 == 0) return null;

            seq[2] = 0;
            return seq;
        }

        return null;
    }
};

pub const Escape = struct {
    pub const clear_screen = "\x1b[2J";
    pub const clear_line = "\x1b[2K";
    pub const cursor_home = "\x1b[H";
    pub const cursor_hide = "\x1b[?25l";
    pub const cursor_show = "\x1b[?25h";
    pub const alt_screen_enter = "\x1b[?1049h";
    pub const alt_screen_leave = "\x1b[?1049l";
    pub const reset = "\x1b[0m";

    pub fn moveCursor(buf: *[32]u8, row: u16, col: u16) []const u8 {
        return std.fmt.bufPrint(buf, "\x1b[{d};{d}H", .{ row + 1, col + 1 }) catch "";
    }
};

pub const Key = struct {
    pub const arrow_up: u8 = 'A';
    pub const arrow_down: u8 = 'B';
    pub const arrow_right: u8 = 'C';
    pub const arrow_left: u8 = 'D';
    pub const escape: u8 = 27;
    pub const enter: u8 = 13;
};

test "terminal size" {
    var term = try Terminal.init();
    defer term.deinit();

    const size = term.getSize();
    try std.testing.expect(size.width > 0);
    try std.testing.expect(size.height > 0);
}
