//! Unified diff output module
//! Text output in the standard unified diff format

const std = @import("std");
const Allocator = std.mem.Allocator;
const hunks_mod = @import("../core/hunks.zig");
const Hunk = hunks_mod.Hunk;
const ChangeKind = hunks_mod.ChangeKind;

pub const Color = struct {
    pub const reset = "\x1b[0m";
    pub const red = "\x1b[31m";
    pub const green = "\x1b[32m";
    pub const cyan = "\x1b[36m";
    pub const bold = "\x1b[1m";
};

pub const OutputConfig = struct {
    use_color: bool = true,
    file1_name: []const u8 = "a",
    file2_name: []const u8 = "b",
};

pub fn formatUnified(
    allocator: Allocator,
    hunk_list: []const Hunk,
    config: OutputConfig,
) ![]u8 {
    var buffer = std.ArrayListUnmanaged(u8).empty;
    errdefer buffer.deinit(allocator);

    try writeHeader(&buffer, allocator, config);

    for (hunk_list) |hunk| {
        try writeHunk(&buffer, allocator, hunk, config);
    }

    return buffer.toOwnedSlice(allocator);
}

fn writeHeader(
    buffer: *std.ArrayListUnmanaged(u8),
    allocator: Allocator,
    config: OutputConfig,
) !void {
    if (config.use_color) {
        try buffer.appendSlice(allocator, Color.bold);
    }
    try buffer.appendSlice(allocator, "--- ");
    try buffer.appendSlice(allocator, config.file1_name);
    try buffer.appendSlice(allocator, "\n");

    try buffer.appendSlice(allocator, "+++ ");
    try buffer.appendSlice(allocator, config.file2_name);
    try buffer.appendSlice(allocator, "\n");

    if (config.use_color) {
        try buffer.appendSlice(allocator, Color.reset);
    }
}

fn writeHunk(
    buffer: *std.ArrayListUnmanaged(u8),
    allocator: Allocator,
    hunk: Hunk,
    config: OutputConfig,
) !void {
    if (config.use_color) {
        try buffer.appendSlice(allocator, Color.cyan);
    }

    var hunk_header_buf: [128]u8 = undefined;
    const hunk_header = std.fmt.bufPrint(&hunk_header_buf, "@@ -{d},{d} +{d},{d} @@\n", .{
        hunk.old_start,
        hunk.old_count,
        hunk.new_start,
        hunk.new_count,
    }) catch return error.OutOfMemory;
    try buffer.appendSlice(allocator, hunk_header);

    if (config.use_color) {
        try buffer.appendSlice(allocator, Color.reset);
    }

    for (hunk.changes) |change| {
        try writeChange(buffer, allocator, change, config);
    }
}

fn writeChange(
    buffer: *std.ArrayListUnmanaged(u8),
    allocator: Allocator,
    change: hunks_mod.Change,
    config: OutputConfig,
) !void {
    switch (change.kind) {
        .context => {
            try buffer.appendSlice(allocator, " ");
        },
        .addition => {
            if (config.use_color) {
                try buffer.appendSlice(allocator, Color.green);
            }
            try buffer.appendSlice(allocator, "+");
        },
        .deletion => {
            if (config.use_color) {
                try buffer.appendSlice(allocator, Color.red);
            }
            try buffer.appendSlice(allocator, "-");
        },
    }

    try buffer.appendSlice(allocator, change.content);

    if (config.use_color and change.kind != .context) {
        try buffer.appendSlice(allocator, Color.reset);
    }

    try buffer.appendSlice(allocator, "\n");
}

pub fn printUnified(
    hunk_list: []const Hunk,
    config: OutputConfig,
) void {
    const stdout: std.fs.File = .{ .handle = std.posix.STDOUT_FILENO };

    if (config.use_color) {
        stdout.writeAll(Color.bold) catch {};
    }
    stdout.writeAll("--- ") catch {};
    stdout.writeAll(config.file1_name) catch {};
    stdout.writeAll("\n") catch {};

    stdout.writeAll("+++ ") catch {};
    stdout.writeAll(config.file2_name) catch {};
    stdout.writeAll("\n") catch {};

    if (config.use_color) {
        stdout.writeAll(Color.reset) catch {};
    }

    for (hunk_list) |hunk| {
        printHunk(stdout, hunk, config);
    }
}

fn printHunk(stdout: std.fs.File, hunk: Hunk, config: OutputConfig) void {
    if (config.use_color) {
        stdout.writeAll(Color.cyan) catch {};
    }

    var buf: [128]u8 = undefined;
    const header = std.fmt.bufPrint(&buf, "@@ -{d},{d} +{d},{d} @@\n", .{
        hunk.old_start,
        hunk.old_count,
        hunk.new_start,
        hunk.new_count,
    }) catch return;
    stdout.writeAll(header) catch {};

    if (config.use_color) {
        stdout.writeAll(Color.reset) catch {};
    }

    for (hunk.changes) |change| {
        printChange(stdout, change, config);
    }
}

fn printChange(stdout: std.fs.File, change: hunks_mod.Change, config: OutputConfig) void {
    switch (change.kind) {
        .context => {
            stdout.writeAll(" ") catch {};
        },
        .addition => {
            if (config.use_color) {
                stdout.writeAll(Color.green) catch {};
            }
            stdout.writeAll("+") catch {};
        },
        .deletion => {
            if (config.use_color) {
                stdout.writeAll(Color.red) catch {};
            }
            stdout.writeAll("-") catch {};
        },
    }

    stdout.writeAll(change.content) catch {};

    if (config.use_color and change.kind != .context) {
        stdout.writeAll(Color.reset) catch {};
    }

    stdout.writeAll("\n") catch {};
}

test "format unified basic" {
    const allocator = std.testing.allocator;

    const changes = &[_]hunks_mod.Change{
        .{ .kind = .context, .content = "line1", .old_line_num = 1, .new_line_num = 1 },
        .{ .kind = .deletion, .content = "old", .old_line_num = 2, .new_line_num = null },
        .{ .kind = .addition, .content = "new", .old_line_num = null, .new_line_num = 2 },
        .{ .kind = .context, .content = "line3", .old_line_num = 3, .new_line_num = 3 },
    };

    const hunk_list = &[_]Hunk{
        .{
            .old_start = 1,
            .old_count = 3,
            .new_start = 1,
            .new_count = 3,
            .changes = @constCast(changes),
        },
    };

    const output = try formatUnified(allocator, hunk_list, .{
        .use_color = false,
        .file1_name = "old.txt",
        .file2_name = "new.txt",
    });
    defer allocator.free(output);

    try std.testing.expect(std.mem.indexOf(u8, output, "--- old.txt") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "+++ new.txt") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "@@ -1,3 +1,3 @@") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, " line1") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "-old") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "+new") != null);
}

test "format unified empty" {
    const allocator = std.testing.allocator;
    const hunk_list: []const Hunk = &.{};

    const output = try formatUnified(allocator, hunk_list, .{
        .use_color = false,
        .file1_name = "a",
        .file2_name = "b",
    });
    defer allocator.free(output);

    try std.testing.expect(std.mem.indexOf(u8, output, "--- a") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "+++ b") != null);
}
