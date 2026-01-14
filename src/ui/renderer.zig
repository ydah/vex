//! Rendering engine module
//! TUI rendering with double buffering

const std = @import("std");
const Allocator = std.mem.Allocator;
const terminal = @import("terminal.zig");
const colors = @import("colors.zig");
const hunks_mod = @import("../core/hunks.zig");

pub const Cell = struct {
    char: u21 = ' ',
    fg: []const u8 = "",
    bg: []const u8 = "",
    bold: bool = false,
};

pub const ScreenBuffer = struct {
    cells: []Cell,
    width: u16,
    height: u16,
    allocator: Allocator,

    pub fn init(allocator: Allocator, width: u16, height: u16) !ScreenBuffer {
        const size = @as(usize, width) * @as(usize, height);
        const cells = try allocator.alloc(Cell, size);
        @memset(cells, Cell{});

        return ScreenBuffer{
            .cells = cells,
            .width = width,
            .height = height,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *ScreenBuffer) void {
        self.allocator.free(self.cells);
    }

    pub fn clear(self: *ScreenBuffer) void {
        @memset(self.cells, Cell{});
    }

    pub fn setCell(self: *ScreenBuffer, x: u16, y: u16, cell: Cell) void {
        if (x >= self.width or y >= self.height) return;
        const idx = @as(usize, y) * @as(usize, self.width) + @as(usize, x);
        self.cells[idx] = cell;
    }

    pub fn writeString(self: *ScreenBuffer, x: u16, y: u16, str: []const u8, fg: []const u8, bg: []const u8) void {
        var col = x;
        for (str) |c| {
            if (col >= self.width) break;
            self.setCell(col, y, .{
                .char = c,
                .fg = fg,
                .bg = bg,
            });
            col += 1;
        }
    }
};

pub const Renderer = struct {
    term: *terminal.Terminal,
    buffer: ScreenBuffer,
    theme: colors.Theme,

    pub fn init(allocator: Allocator, term: *terminal.Terminal, theme: colors.Theme) !Renderer {
        const size = term.getSize();
        const buffer = try ScreenBuffer.init(allocator, size.width, size.height);

        return Renderer{
            .term = term,
            .buffer = buffer,
            .theme = theme,
        };
    }

    pub fn deinit(self: *Renderer) void {
        self.buffer.deinit();
    }

    pub fn clear(self: *Renderer) void {
        self.buffer.clear();
    }

    pub fn flush(self: *Renderer) void {
        var output_buf: [8192]u8 = undefined;
        var fbs = std.io.fixedBufferStream(&output_buf);
        const writer = fbs.writer();

        writer.writeAll(terminal.Escape.cursor_home) catch {};
        writer.writeAll(self.theme.bg) catch {};

        var last_fg: []const u8 = "";
        var last_bg: []const u8 = "";

        var y: u16 = 0;
        while (y < self.buffer.height) : (y += 1) {
            var x: u16 = 0;
            while (x < self.buffer.width) : (x += 1) {
                const idx = @as(usize, y) * @as(usize, self.buffer.width) + @as(usize, x);
                const cell = self.buffer.cells[idx];

                if (!std.mem.eql(u8, cell.fg, last_fg)) {
                    if (cell.fg.len > 0) {
                        writer.writeAll(cell.fg) catch {};
                    } else {
                        writer.writeAll(self.theme.fg) catch {};
                    }
                    last_fg = cell.fg;
                }

                if (!std.mem.eql(u8, cell.bg, last_bg)) {
                    if (cell.bg.len > 0) {
                        writer.writeAll(cell.bg) catch {};
                    }
                    last_bg = cell.bg;
                }

                if (cell.bold) {
                    writer.writeAll(colors.Color.bold) catch {};
                }

                var char_buf: [4]u8 = undefined;
                const len = std.unicode.utf8Encode(cell.char, &char_buf) catch 1;
                writer.writeAll(char_buf[0..len]) catch {};
            }

            if (y < self.buffer.height - 1) {
                writer.writeAll("\r\n") catch {};
            }

            if (fbs.pos > 7000) {
                self.term.write(fbs.getWritten());
                fbs.reset();
            }
        }

        writer.writeAll(colors.Color.reset) catch {};
        self.term.write(fbs.getWritten());
    }

    pub fn drawBox(self: *Renderer, x: u16, y: u16, w: u16, h: u16) void {
        self.buffer.writeString(x, y, "┌", self.theme.border, "");
        var i: u16 = 1;
        while (i < w - 1) : (i += 1) {
            self.buffer.writeString(x + i, y, "─", self.theme.border, "");
        }
        self.buffer.writeString(x + w - 1, y, "┐", self.theme.border, "");

        var row: u16 = 1;
        while (row < h - 1) : (row += 1) {
            self.buffer.writeString(x, y + row, "│", self.theme.border, "");
            self.buffer.writeString(x + w - 1, y + row, "│", self.theme.border, "");
        }

        self.buffer.writeString(x, y + h - 1, "└", self.theme.border, "");
        i = 1;
        while (i < w - 1) : (i += 1) {
            self.buffer.writeString(x + i, y + h - 1, "─", self.theme.border, "");
        }
        self.buffer.writeString(x + w - 1, y + h - 1, "┘", self.theme.border, "");
    }

    pub fn drawText(self: *Renderer, x: u16, y: u16, text: []const u8, fg: []const u8) void {
        self.buffer.writeString(x, y, text, fg, "");
    }

    pub fn drawStatusBar(self: *Renderer, text: []const u8) void {
        const y = self.buffer.height - 1;
        var x: u16 = 0;
        while (x < self.buffer.width) : (x += 1) {
            self.buffer.setCell(x, y, .{
                .char = ' ',
                .fg = self.theme.fg,
                .bg = self.theme.modification_bg,
            });
        }
        self.buffer.writeString(0, y, text, self.theme.fg, self.theme.modification_bg);
    }
};

test "screen buffer" {
    const allocator = std.testing.allocator;
    var buf = try ScreenBuffer.init(allocator, 80, 24);
    defer buf.deinit();

    buf.setCell(0, 0, .{ .char = 'A' });
    try std.testing.expectEqual(@as(u21, 'A'), buf.cells[0].char);

    buf.clear();
    try std.testing.expectEqual(@as(u21, ' '), buf.cells[0].char);
}
