//! vex - Zig-based AST-aware diff tool
//! Modern diff viewer that understands syntax

const std = @import("std");
const cli = @import("cli.zig");
const io = @import("utils/io.zig");
const diff = @import("core/diff.zig");
const hunks = @import("core/hunks.zig");
const unified = @import("output/unified.zig");
const side_by_side = @import("output/side_by_side.zig");
const tui = @import("ui/tui.zig");
const ui_terminal = @import("ui/terminal.zig");
const ui_colors = @import("ui/colors.zig");
const ui_renderer = @import("ui/renderer.zig");
const ui_input = @import("ui/input.zig");
const editor_buffer = @import("editor/buffer.zig");
const editor_ops = @import("editor/operations.zig");
const editor_undo = @import("editor/undo.zig");
const simd = @import("utils/simd.zig");

pub fn main() !void {
    const args = std.process.argsAlloc(std.heap.page_allocator) catch {
        const stderr: std.fs.File = .{ .handle = std.posix.STDERR_FILENO };
        stderr.writeAll("error: failed to get arguments\n") catch {};
        return;
    };
    defer std.process.argsFree(std.heap.page_allocator, args);

    const result = cli.parse(args);

    switch (result) {
        .help => cli.printHelp(),
        .version => cli.printVersion(),
        .err => |err| cli.printError(err),
        .config => |config| {
            runDiff(config) catch |err| {
                const stderr: std.fs.File = .{ .handle = std.posix.STDERR_FILENO };
                const msg = switch (err) {
                    error.FileNotFound => "error: file not found\n",
                    error.AccessDenied => "error: access denied\n",
                    error.OutOfMemory => "error: out of memory\n",
                    else => "error: failed to compute diff\n",
                };
                stderr.writeAll(msg) catch {};
            };
        },
    }
}

fn runDiff(config: cli.Config) !void {
    const allocator = std.heap.page_allocator;

    var file1_content = try io.readFileOrStdin(allocator, config.file1);
    defer file1_content.deinit();

    var file2_content = try io.readFileOrStdin(allocator, config.file2);
    defer file2_content.deinit();

    const old_lines = try io.splitLines(allocator, file1_content.data);
    defer allocator.free(old_lines);

    const new_lines = try io.splitLines(allocator, file2_content.data);
    defer allocator.free(new_lines);

    const edits = try diff.computeDiff(allocator, old_lines, new_lines);
    defer allocator.free(edits);

    const hunk_list = try hunks.generateHunks(allocator, edits, config.context_lines);
    defer hunks.freeHunks(allocator, hunk_list);

    var term = try ui_terminal.Terminal.init();
    defer term.deinit();
    const term_width: u32 = @intCast(term.getSize().width);
    const output_width: u32 = if (term_width < 40) 40 else term_width;

    switch (config.mode) {
        .unified => unified.printUnified(hunk_list, .{
            .use_color = config.use_color,
            .file1_name = config.file1,
            .file2_name = config.file2,
        }),
        .side_by_side => side_by_side.printSideBySide(hunk_list, .{
            .use_color = config.use_color,
            .file1_name = config.file1,
            .file2_name = config.file2,
            .width = output_width,
        }),
    }
}

test "main module" {
    _ = cli;
    _ = io;
    _ = diff;
    _ = hunks;
    _ = unified;
    _ = side_by_side;
    _ = tui;
    _ = ui_terminal;
    _ = ui_colors;
    _ = ui_renderer;
    _ = ui_input;
    _ = editor_buffer;
    _ = editor_ops;
    _ = editor_undo;
    _ = simd;
}
