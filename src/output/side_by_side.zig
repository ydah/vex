//! Side-by-side view module
//! Render old/new files in parallel columns

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
    pub const dim = "\x1b[2m";
    pub const bg_red = "\x1b[41m";
    pub const bg_green = "\x1b[42m";
};

pub const OutputConfig = struct {
    use_color: bool = true,
    file1_name: []const u8 = "a",
    file2_name: []const u8 = "b",
    width: u32 = 80,
    line_number_width: u32 = 4,
};

pub fn printSideBySide(
    hunk_list: []const Hunk,
    config: OutputConfig,
) void {
    const stdout: std.fs.File = .{ .handle = std.posix.STDOUT_FILENO };
    const panel_width = (config.width - 3) / 2;

    printHeader(stdout, config, panel_width);
    printSeparator(stdout, config, panel_width);

    for (hunk_list) |hunk| {
        printHunkHeader(stdout, hunk, config, panel_width);

        for (hunk.changes) |change| {
            printChangeLine(stdout, change, config, panel_width);
        }
    }

    printSeparator(stdout, config, panel_width);
}

fn printHeader(stdout: std.fs.File, config: OutputConfig, panel_width: u32) void {
    if (config.use_color) {
        stdout.writeAll(Color.bold) catch {};
    }

    printPaddedString(stdout, config.file1_name, panel_width);
    stdout.writeAll(" │ ") catch {};
    printPaddedString(stdout, config.file2_name, panel_width);
    stdout.writeAll("\n") catch {};

    if (config.use_color) {
        stdout.writeAll(Color.reset) catch {};
    }
}

fn printSeparator(stdout: std.fs.File, config: OutputConfig, panel_width: u32) void {
    if (config.use_color) {
        stdout.writeAll(Color.dim) catch {};
    }

    var i: u32 = 0;
    while (i < panel_width) : (i += 1) {
        stdout.writeAll("─") catch {};
    }
    stdout.writeAll("─┼─") catch {};

    i = 0;
    while (i < panel_width) : (i += 1) {
        stdout.writeAll("─") catch {};
    }
    stdout.writeAll("\n") catch {};

    if (config.use_color) {
        stdout.writeAll(Color.reset) catch {};
    }
}

fn printHunkHeader(stdout: std.fs.File, hunk: Hunk, config: OutputConfig, panel_width: u32) void {
    if (config.use_color) {
        stdout.writeAll(Color.cyan) catch {};
    }

    var buf: [64]u8 = undefined;
    const left = std.fmt.bufPrint(&buf, "@@ -{d},{d}", .{ hunk.old_start, hunk.old_count }) catch return;
    printPaddedString(stdout, left, panel_width);

    stdout.writeAll(" │ ") catch {};

    var buf2: [64]u8 = undefined;
    const right = std.fmt.bufPrint(&buf2, "+{d},{d} @@", .{ hunk.new_start, hunk.new_count }) catch return;
    printPaddedString(stdout, right, panel_width);

    stdout.writeAll("\n") catch {};

    if (config.use_color) {
        stdout.writeAll(Color.reset) catch {};
    }
}

fn printChangeLine(stdout: std.fs.File, change: hunks_mod.Change, config: OutputConfig, panel_width: u32) void {
    const ln_width = config.line_number_width;
    const content_width = panel_width - ln_width - 1;

    switch (change.kind) {
        .context => {
            printLineNumber(stdout, change.old_line_num, ln_width, config);
            stdout.writeAll(" ") catch {};
            printTruncatedContent(stdout, change.content, content_width);
            stdout.writeAll(" │ ") catch {};
            printLineNumber(stdout, change.new_line_num, ln_width, config);
            stdout.writeAll(" ") catch {};
            printTruncatedContent(stdout, change.content, content_width);
        },
        .deletion => {
            if (config.use_color) {
                stdout.writeAll(Color.red) catch {};
            }
            printLineNumber(stdout, change.old_line_num, ln_width, config);
            stdout.writeAll("-") catch {};
            printTruncatedContent(stdout, change.content, content_width);
            if (config.use_color) {
                stdout.writeAll(Color.reset) catch {};
            }
            stdout.writeAll(" │ ") catch {};
            printPadding(stdout, panel_width);
        },
        .addition => {
            printPadding(stdout, panel_width);
            stdout.writeAll(" │ ") catch {};
            if (config.use_color) {
                stdout.writeAll(Color.green) catch {};
            }
            printLineNumber(stdout, change.new_line_num, ln_width, config);
            stdout.writeAll("+") catch {};
            printTruncatedContent(stdout, change.content, content_width);
            if (config.use_color) {
                stdout.writeAll(Color.reset) catch {};
            }
        },
    }

    stdout.writeAll("\n") catch {};
}

fn printLineNumber(stdout: std.fs.File, line_num: ?u32, width: u32, config: OutputConfig) void {
    if (line_num) |num| {
        var buf: [16]u8 = undefined;
        const num_str = std.fmt.bufPrint(&buf, "{d}", .{num}) catch return;

        if (config.use_color) {
            stdout.writeAll(Color.dim) catch {};
        }

        const padding = if (width > num_str.len) width - @as(u32, @intCast(num_str.len)) else 0;
        var i: u32 = 0;
        while (i < padding) : (i += 1) {
            stdout.writeAll(" ") catch {};
        }
        stdout.writeAll(num_str) catch {};

        if (config.use_color) {
            stdout.writeAll(Color.reset) catch {};
        }
    } else {
        var i: u32 = 0;
        while (i < width) : (i += 1) {
            stdout.writeAll(" ") catch {};
        }
    }
}

fn printTruncatedContent(stdout: std.fs.File, content: []const u8, max_width: u32) void {
    const len = @min(content.len, max_width);
    stdout.writeAll(content[0..len]) catch {};

    if (content.len < max_width) {
        const padding = max_width - @as(u32, @intCast(content.len));
        var i: u32 = 0;
        while (i < padding) : (i += 1) {
            stdout.writeAll(" ") catch {};
        }
    }
}

fn printPaddedString(stdout: std.fs.File, str: []const u8, width: u32) void {
    const len = @min(str.len, width);
    stdout.writeAll(str[0..len]) catch {};

    if (str.len < width) {
        const padding = width - @as(u32, @intCast(str.len));
        var i: u32 = 0;
        while (i < padding) : (i += 1) {
            stdout.writeAll(" ") catch {};
        }
    }
}

fn printPadding(stdout: std.fs.File, width: u32) void {
    var i: u32 = 0;
    while (i < width) : (i += 1) {
        stdout.writeAll(" ") catch {};
    }
}

test "side by side module exists" {
    _ = Color;
    _ = OutputConfig;
}
