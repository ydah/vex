//! Editor buffer module
//! Text management via a gap buffer

const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Position = struct {
    line: usize,
    col: usize,
};

pub const Line = struct {
    content: []u8,
    allocator: Allocator,

    pub fn init(allocator: Allocator, content: []const u8) !Line {
        const data = try allocator.alloc(u8, content.len);
        @memcpy(data, content);
        return Line{
            .content = data,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Line) void {
        self.allocator.free(self.content);
    }

    pub fn insert(self: *Line, col: usize, char: u8) !void {
        const new_content = try self.allocator.alloc(u8, self.content.len + 1);
        const insert_pos = @min(col, self.content.len);

        @memcpy(new_content[0..insert_pos], self.content[0..insert_pos]);
        new_content[insert_pos] = char;
        @memcpy(new_content[insert_pos + 1 ..], self.content[insert_pos..]);

        self.allocator.free(self.content);
        self.content = new_content;
    }

    pub fn delete(self: *Line, col: usize) !void {
        if (self.content.len == 0 or col >= self.content.len) return;

        const new_content = try self.allocator.alloc(u8, self.content.len - 1);

        @memcpy(new_content[0..col], self.content[0..col]);
        if (col < self.content.len - 1) {
            @memcpy(new_content[col..], self.content[col + 1 ..]);
        }

        self.allocator.free(self.content);
        self.content = new_content;
    }
};

pub const Buffer = struct {
    lines: std.ArrayListUnmanaged(Line),
    allocator: Allocator,
    cursor: Position,
    modified: bool,

    pub fn init(allocator: Allocator) Buffer {
        return Buffer{
            .lines = .empty,
            .allocator = allocator,
            .cursor = .{ .line = 0, .col = 0 },
            .modified = false,
        };
    }

    pub fn deinit(self: *Buffer) void {
        for (self.lines.items) |*line| {
            line.deinit();
        }
        self.lines.deinit(self.allocator);
    }

    pub fn loadContent(self: *Buffer, content: []const u8) !void {
        self.clear();

        var start: usize = 0;
        for (content, 0..) |c, i| {
            if (c == '\n') {
                const line = try Line.init(self.allocator, content[start..i]);
                try self.lines.append(self.allocator, line);
                start = i + 1;
            }
        }

        if (start < content.len) {
            const line = try Line.init(self.allocator, content[start..]);
            try self.lines.append(self.allocator, line);
        }

        if (self.lines.items.len == 0) {
            const empty = try Line.init(self.allocator, "");
            try self.lines.append(self.allocator, empty);
        }

        self.cursor = .{ .line = 0, .col = 0 };
        self.modified = false;
    }

    pub fn clear(self: *Buffer) void {
        for (self.lines.items) |*line| {
            line.deinit();
        }
        self.lines.clearRetainingCapacity();
    }

    pub fn insertChar(self: *Buffer, char: u8) !void {
        if (self.cursor.line >= self.lines.items.len) return;

        try self.lines.items[self.cursor.line].insert(self.cursor.col, char);
        self.cursor.col += 1;
        self.modified = true;
    }

    pub fn deleteChar(self: *Buffer) !void {
        if (self.cursor.line >= self.lines.items.len) return;
        if (self.cursor.col == 0) return;

        self.cursor.col -= 1;
        try self.lines.items[self.cursor.line].delete(self.cursor.col);
        self.modified = true;
    }

    pub fn insertNewline(self: *Buffer) !void {
        if (self.cursor.line >= self.lines.items.len) return;

        const current = &self.lines.items[self.cursor.line];
        const rest = if (self.cursor.col < current.content.len)
            current.content[self.cursor.col..]
        else
            "";

        const new_line = try Line.init(self.allocator, rest);

        if (self.cursor.col < current.content.len) {
            const truncated = try self.allocator.alloc(u8, self.cursor.col);
            @memcpy(truncated, current.content[0..self.cursor.col]);
            self.allocator.free(current.content);
            current.content = truncated;
        }

        try self.lines.insert(self.allocator, self.cursor.line + 1, new_line);

        self.cursor.line += 1;
        self.cursor.col = 0;
        self.modified = true;
    }

    pub fn moveCursor(self: *Buffer, d_line: i32, d_col: i32) void {
        if (d_line < 0 and self.cursor.line > 0) {
            self.cursor.line -= 1;
        } else if (d_line > 0 and self.cursor.line < self.lines.items.len - 1) {
            self.cursor.line += 1;
        }

        if (self.cursor.line < self.lines.items.len) {
            const line_len = self.lines.items[self.cursor.line].content.len;

            if (d_col < 0 and self.cursor.col > 0) {
                self.cursor.col -= 1;
            } else if (d_col > 0 and self.cursor.col < line_len) {
                self.cursor.col += 1;
            }

            self.cursor.col = @min(self.cursor.col, line_len);
        }
    }

    pub fn getLine(self: *Buffer, line_num: usize) ?[]const u8 {
        if (line_num >= self.lines.items.len) return null;
        return self.lines.items[line_num].content;
    }

    pub fn lineCount(self: *Buffer) usize {
        return self.lines.items.len;
    }

    pub fn toContent(self: *Buffer, allocator: Allocator) ![]u8 {
        var total_len: usize = 0;
        for (self.lines.items) |line| {
            total_len += line.content.len + 1;
        }

        const content = try allocator.alloc(u8, total_len);
        var offset: usize = 0;

        for (self.lines.items) |line| {
            @memcpy(content[offset .. offset + line.content.len], line.content);
            offset += line.content.len;
            content[offset] = '\n';
            offset += 1;
        }

        return content;
    }
};

test "buffer insert char" {
    const allocator = std.testing.allocator;
    var buf = Buffer.init(allocator);
    defer buf.deinit();

    try buf.loadContent("hello");
    try buf.insertChar('X');

    try std.testing.expectEqualStrings("Xhello", buf.lines.items[0].content);
}

test "buffer delete char" {
    const allocator = std.testing.allocator;
    var buf = Buffer.init(allocator);
    defer buf.deinit();

    try buf.loadContent("hello");
    buf.cursor.col = 3;
    try buf.deleteChar();

    try std.testing.expectEqualStrings("helo", buf.lines.items[0].content);
}

test "buffer newline" {
    const allocator = std.testing.allocator;
    var buf = Buffer.init(allocator);
    defer buf.deinit();

    try buf.loadContent("hello world");
    buf.cursor.col = 5;
    try buf.insertNewline();

    try std.testing.expectEqual(@as(usize, 2), buf.lineCount());
    try std.testing.expectEqualStrings("hello", buf.lines.items[0].content);
    try std.testing.expectEqualStrings(" world", buf.lines.items[1].content);
}

test "buffer load content" {
    const allocator = std.testing.allocator;
    var buf = Buffer.init(allocator);
    defer buf.deinit();

    try buf.loadContent("line1\nline2\nline3");

    try std.testing.expectEqual(@as(usize, 3), buf.lineCount());
    try std.testing.expectEqualStrings("line1", buf.getLine(0).?);
    try std.testing.expectEqualStrings("line2", buf.getLine(1).?);
    try std.testing.expectEqualStrings("line3", buf.getLine(2).?);
}
