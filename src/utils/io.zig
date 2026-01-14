//! File I/O module
//! File loading and stdin support

const std = @import("std");
const Allocator = std.mem.Allocator;

pub const FileContent = struct {
    data: []const u8,
    allocator: Allocator,

    pub fn deinit(self: *FileContent) void {
        self.allocator.free(self.data);
    }
};

pub const ReadError = error{
    FileNotFound,
    AccessDenied,
    OutOfMemory,
    IoError,
    IsDirectory,
};

pub fn readFile(allocator: Allocator, path: []const u8) ReadError!FileContent {
    const file = std.fs.cwd().openFile(path, .{}) catch |err| {
        return switch (err) {
            error.FileNotFound => ReadError.FileNotFound,
            error.AccessDenied => ReadError.AccessDenied,
            error.IsDir => ReadError.IsDirectory,
            else => ReadError.IoError,
        };
    };
    defer file.close();

    const stat = file.stat() catch {
        return ReadError.IoError;
    };

    const data = allocator.alloc(u8, stat.size) catch {
        return ReadError.OutOfMemory;
    };
    errdefer allocator.free(data);

    const bytes_read = file.readAll(data) catch {
        return ReadError.IoError;
    };

    return FileContent{
        .data = data[0..bytes_read],
        .allocator = allocator,
    };
}

pub fn readStdin(allocator: Allocator) ReadError!FileContent {
    const stdin_file: std.fs.File = .{ .handle = std.posix.STDIN_FILENO };

    var buffer: std.ArrayListUnmanaged(u8) = .empty;
    errdefer buffer.deinit(allocator);

    var read_buf: [4096]u8 = undefined;
    while (true) {
        const bytes_read = stdin_file.read(&read_buf) catch {
            return ReadError.IoError;
        };
        if (bytes_read == 0) break;
        buffer.appendSlice(allocator, read_buf[0..bytes_read]) catch {
            return ReadError.OutOfMemory;
        };
    }

    const data = buffer.toOwnedSlice(allocator) catch {
        return ReadError.OutOfMemory;
    };

    return FileContent{
        .data = data,
        .allocator = allocator,
    };
}

pub fn readFileOrStdin(allocator: Allocator, path: []const u8) ReadError!FileContent {
    if (std.mem.eql(u8, path, "-")) {
        return readStdin(allocator);
    }
    return readFile(allocator, path);
}

pub const LineIterator = struct {
    content: []const u8,
    index: usize,

    pub fn init(content: []const u8) LineIterator {
        return .{
            .content = content,
            .index = 0,
        };
    }

    pub fn next(self: *LineIterator) ?[]const u8 {
        if (self.index >= self.content.len) return null;

        const start = self.index;
        while (self.index < self.content.len and self.content[self.index] != '\n') {
            self.index += 1;
        }

        const line = self.content[start..self.index];

        if (self.index < self.content.len) {
            self.index += 1;
        }

        return line;
    }
};

pub fn splitLines(allocator: Allocator, content: []const u8) ![]const []const u8 {
    var line_count: usize = 0;
    for (content) |c| {
        if (c == '\n') line_count += 1;
    }
    if (content.len > 0 and content[content.len - 1] != '\n') {
        line_count += 1;
    }

    const lines = try allocator.alloc([]const u8, line_count);
    errdefer allocator.free(lines);

    var iter = LineIterator.init(content);
    var i: usize = 0;
    while (iter.next()) |line| {
        lines[i] = line;
        i += 1;
    }

    return lines[0..i];
}

test "splitLines basic" {
    const allocator = std.testing.allocator;
    const content = "line1\nline2\nline3\n";
    const lines = try splitLines(allocator, content);
    defer allocator.free(lines);

    try std.testing.expectEqual(@as(usize, 3), lines.len);
    try std.testing.expectEqualStrings("line1", lines[0]);
    try std.testing.expectEqualStrings("line2", lines[1]);
    try std.testing.expectEqualStrings("line3", lines[2]);
}

test "splitLines no trailing newline" {
    const allocator = std.testing.allocator;
    const content = "line1\nline2";
    const lines = try splitLines(allocator, content);
    defer allocator.free(lines);

    try std.testing.expectEqual(@as(usize, 2), lines.len);
    try std.testing.expectEqualStrings("line1", lines[0]);
    try std.testing.expectEqualStrings("line2", lines[1]);
}

test "splitLines empty" {
    const allocator = std.testing.allocator;
    const content = "";
    const lines = try splitLines(allocator, content);
    defer allocator.free(lines);

    try std.testing.expectEqual(@as(usize, 0), lines.len);
}

test "LineIterator basic" {
    const content = "a\nb\nc";
    var iter = LineIterator.init(content);

    try std.testing.expectEqualStrings("a", iter.next().?);
    try std.testing.expectEqualStrings("b", iter.next().?);
    try std.testing.expectEqualStrings("c", iter.next().?);
    try std.testing.expectEqual(@as(?[]const u8, null), iter.next());
}
