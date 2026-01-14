//! CLI argument parser module
//! Parse command-line arguments and build the config

const std = @import("std");
const Allocator = std.mem.Allocator;

pub const version = "0.1.0";

pub const ViewMode = enum {
    side_by_side,
    unified,
};

pub const Config = struct {
    file1: []const u8,
    file2: []const u8,
    mode: ViewMode,
    ast_aware: bool,
    use_color: bool,
    context_lines: u32,
};

pub const ParseError = error{
    MissingFile1,
    MissingFile2,
    InvalidContextValue,
    UnknownOption,
    HelpRequested,
    VersionRequested,
};

pub const ParseResult = union(enum) {
    config: Config,
    help,
    version,
    err: ParseError,
};

fn getStdout() std.fs.File {
    return .{ .handle = std.posix.STDOUT_FILENO };
}

fn getStderr() std.fs.File {
    return .{ .handle = std.posix.STDERR_FILENO };
}

pub fn parse(args: []const []const u8) ParseResult {
    var mode: ViewMode = .side_by_side;
    var ast_aware: bool = false;
    var use_color: bool = true;
    var context_lines: u32 = 3;
    var file1: ?[]const u8 = null;
    var file2: ?[]const u8 = null;

    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        const arg = args[i];

        if (std.mem.startsWith(u8, arg, "-")) {
            if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
                return .help;
            } else if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--version")) {
                return .version;
            } else if (std.mem.eql(u8, arg, "-s") or std.mem.eql(u8, arg, "--side-by-side")) {
                mode = .side_by_side;
            } else if (std.mem.eql(u8, arg, "-u") or std.mem.eql(u8, arg, "--unified")) {
                mode = .unified;
            } else if (std.mem.eql(u8, arg, "--ast")) {
                ast_aware = true;
            } else if (std.mem.eql(u8, arg, "--no-color")) {
                use_color = false;
            } else if (std.mem.eql(u8, arg, "-c") or std.mem.eql(u8, arg, "--context")) {
                i += 1;
                if (i >= args.len) {
                    return .{ .err = ParseError.InvalidContextValue };
                }
                context_lines = std.fmt.parseInt(u32, args[i], 10) catch {
                    return .{ .err = ParseError.InvalidContextValue };
                };
            } else {
                return .{ .err = ParseError.UnknownOption };
            }
        } else {
            if (file1 == null) {
                file1 = arg;
            } else if (file2 == null) {
                file2 = arg;
            }
        }
    }

    if (file1 == null) {
        return .{ .err = ParseError.MissingFile1 };
    }
    if (file2 == null) {
        return .{ .err = ParseError.MissingFile2 };
    }

    return .{
        .config = .{
            .file1 = file1.?,
            .file2 = file2.?,
            .mode = mode,
            .ast_aware = ast_aware,
            .use_color = use_color,
            .context_lines = context_lines,
        },
    };
}

pub fn printHelp() void {
    const stdout = getStdout();
    stdout.writeAll(
        \\vex - AST-aware diff tool
        \\
        \\USAGE:
        \\    vex [OPTIONS] <file1> <file2>
        \\
        \\ARGUMENTS:
        \\    <file1>    First file to compare (use '-' for stdin)
        \\    <file2>    Second file to compare
        \\
        \\OPTIONS:
        \\    -s, --side-by-side    Side-by-side display mode (default)
        \\    -u, --unified         Unified diff format
        \\    --ast                 Enable AST-aware diff mode
        \\    --no-color            Disable color output
        \\    -c, --context <N>     Number of context lines (default: 3)
        \\    -h, --help            Show this help message
        \\    -v, --version         Show version information
        \\
        \\EXAMPLES:
        \\    vex old.zig new.zig
        \\    vex -s --ast src/old.rs src/new.rs
        \\    cat file.txt | vex - other.txt
        \\
    ) catch {};
}

pub fn printVersion() void {
    const stdout = getStdout();
    stdout.writeAll("vex " ++ version ++ "\n") catch {};
}

pub fn printError(err: ParseError) void {
    const stderr = getStderr();
    const msg = switch (err) {
        ParseError.MissingFile1 => "error: missing first file argument\n",
        ParseError.MissingFile2 => "error: missing second file argument\n",
        ParseError.InvalidContextValue => "error: invalid context value\n",
        ParseError.UnknownOption => "error: unknown option\n",
        ParseError.HelpRequested => "",
        ParseError.VersionRequested => "",
    };
    stderr.writeAll(msg) catch {};
    stderr.writeAll("Run 'vex --help' for usage information.\n") catch {};
}

test "parse basic arguments" {
    const args = &[_][]const u8{ "vex", "file1.txt", "file2.txt" };
    const result = parse(args);
    switch (result) {
        .config => |config| {
            try std.testing.expectEqualStrings("file1.txt", config.file1);
            try std.testing.expectEqualStrings("file2.txt", config.file2);
            try std.testing.expectEqual(ViewMode.side_by_side, config.mode);
            try std.testing.expect(!config.ast_aware);
            try std.testing.expect(config.use_color);
            try std.testing.expectEqual(@as(u32, 3), config.context_lines);
        },
        else => return error.TestUnexpectedResult,
    }
}

test "parse with options" {
    const args = &[_][]const u8{ "vex", "-u", "--no-color", "--ast", "a.txt", "b.txt" };
    const result = parse(args);
    switch (result) {
        .config => |config| {
            try std.testing.expectEqual(ViewMode.unified, config.mode);
            try std.testing.expect(config.ast_aware);
            try std.testing.expect(!config.use_color);
        },
        else => return error.TestUnexpectedResult,
    }
}

test "parse context option" {
    const args = &[_][]const u8{ "vex", "-c", "5", "a.txt", "b.txt" };
    const result = parse(args);
    switch (result) {
        .config => |config| {
            try std.testing.expectEqual(@as(u32, 5), config.context_lines);
        },
        else => return error.TestUnexpectedResult,
    }
}

test "parse help flag" {
    const args = &[_][]const u8{ "vex", "--help" };
    const result = parse(args);
    try std.testing.expectEqual(ParseResult.help, result);
}

test "parse version flag" {
    const args = &[_][]const u8{ "vex", "-v" };
    const result = parse(args);
    try std.testing.expectEqual(ParseResult.version, result);
}

test "parse missing file error" {
    const args = &[_][]const u8{"vex"};
    const result = parse(args);
    switch (result) {
        .err => |err| {
            try std.testing.expectEqual(ParseError.MissingFile1, err);
        },
        else => return error.TestUnexpectedResult,
    }
}
