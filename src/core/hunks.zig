//! Hunk generation module
//! Convert edit runs into hunks (diff blocks)

const std = @import("std");
const Allocator = std.mem.Allocator;
const diff = @import("diff.zig");

pub const ChangeKind = enum {
    context,
    addition,
    deletion,
};

pub const Change = struct {
    kind: ChangeKind,
    content: []const u8,
    old_line_num: ?u32,
    new_line_num: ?u32,
};

pub const Hunk = struct {
    old_start: u32,
    old_count: u32,
    new_start: u32,
    new_count: u32,
    changes: []Change,
};

pub const HunkError = error{
    OutOfMemory,
};

pub fn generateHunks(
    allocator: Allocator,
    edits: []const diff.Edit,
    context_lines: u32,
) HunkError![]Hunk {
    if (edits.len == 0) {
        return allocator.alloc(Hunk, 0) catch return HunkError.OutOfMemory;
    }

    var change_indices = std.ArrayListUnmanaged(usize).empty;
    defer change_indices.deinit(allocator);

    for (edits, 0..) |edit, i| {
        if (edit.kind != .equal) {
            change_indices.append(allocator, i) catch return HunkError.OutOfMemory;
        }
    }

    if (change_indices.items.len == 0) {
        return allocator.alloc(Hunk, 0) catch return HunkError.OutOfMemory;
    }

    var hunk_ranges = std.ArrayListUnmanaged([2]usize).empty;
    defer hunk_ranges.deinit(allocator);

    var current_start: usize = 0;
    var current_end: usize = 0;

    for (change_indices.items, 0..) |change_idx, i| {
        const ctx: usize = @intCast(context_lines);

        if (i == 0) {
            current_start = if (change_idx > ctx) change_idx - ctx else 0;
            current_end = @min(change_idx + ctx + 1, edits.len);
        } else {
            const new_start = if (change_idx > ctx) change_idx - ctx else 0;

            if (new_start <= current_end) {
                current_end = @min(change_idx + ctx + 1, edits.len);
            } else {
                hunk_ranges.append(allocator, .{ current_start, current_end }) catch return HunkError.OutOfMemory;
                current_start = new_start;
                current_end = @min(change_idx + ctx + 1, edits.len);
            }
        }
    }

    hunk_ranges.append(allocator, .{ current_start, current_end }) catch return HunkError.OutOfMemory;

    var hunks = std.ArrayListUnmanaged(Hunk).empty;
    errdefer {
        for (hunks.items) |hunk| {
            allocator.free(hunk.changes);
        }
        hunks.deinit(allocator);
    }

    for (hunk_ranges.items) |range| {
        const hunk = try buildHunk(allocator, edits, range[0], range[1]);
        hunks.append(allocator, hunk) catch return HunkError.OutOfMemory;
    }

    return hunks.toOwnedSlice(allocator) catch return HunkError.OutOfMemory;
}

fn buildHunk(
    allocator: Allocator,
    edits: []const diff.Edit,
    start: usize,
    end: usize,
) HunkError!Hunk {
    var changes = std.ArrayListUnmanaged(Change).empty;
    errdefer changes.deinit(allocator);

    var old_start: ?u32 = null;
    var new_start: ?u32 = null;
    var old_count: u32 = 0;
    var new_count: u32 = 0;

    for (edits[start..end]) |edit| {
        const change = switch (edit.kind) {
            .equal => Change{
                .kind = .context,
                .content = edit.old_line orelse "",
                .old_line_num = if (edit.old_idx) |idx| @intCast(idx + 1) else null,
                .new_line_num = if (edit.new_idx) |idx| @intCast(idx + 1) else null,
            },
            .insert => Change{
                .kind = .addition,
                .content = edit.new_line orelse "",
                .old_line_num = null,
                .new_line_num = if (edit.new_idx) |idx| @intCast(idx + 1) else null,
            },
            .delete => Change{
                .kind = .deletion,
                .content = edit.old_line orelse "",
                .old_line_num = if (edit.old_idx) |idx| @intCast(idx + 1) else null,
                .new_line_num = null,
            },
        };

        changes.append(allocator, change) catch return HunkError.OutOfMemory;

        switch (edit.kind) {
            .equal => {
                if (old_start == null) {
                    if (edit.old_idx) |idx| old_start = @intCast(idx + 1);
                }
                if (new_start == null) {
                    if (edit.new_idx) |idx| new_start = @intCast(idx + 1);
                }
                old_count += 1;
                new_count += 1;
            },
            .insert => {
                if (new_start == null) {
                    if (edit.new_idx) |idx| new_start = @intCast(idx + 1);
                }
                new_count += 1;
            },
            .delete => {
                if (old_start == null) {
                    if (edit.old_idx) |idx| old_start = @intCast(idx + 1);
                }
                old_count += 1;
            },
        }
    }

    return Hunk{
        .old_start = old_start orelse 1,
        .old_count = old_count,
        .new_start = new_start orelse 1,
        .new_count = new_count,
        .changes = changes.toOwnedSlice(allocator) catch return HunkError.OutOfMemory,
    };
}

pub fn freeHunks(allocator: Allocator, hunks: []Hunk) void {
    for (hunks) |hunk| {
        allocator.free(hunk.changes);
    }
    allocator.free(hunks);
}

test "generate hunks basic" {
    const allocator = std.testing.allocator;

    const edits = &[_]diff.Edit{
        .{ .kind = .equal, .old_idx = 0, .new_idx = 0, .old_line = "a", .new_line = "a" },
        .{ .kind = .delete, .old_idx = 1, .new_idx = null, .old_line = "b", .new_line = null },
        .{ .kind = .insert, .old_idx = null, .new_idx = 1, .old_line = null, .new_line = "c" },
        .{ .kind = .equal, .old_idx = 2, .new_idx = 2, .old_line = "d", .new_line = "d" },
    };

    const hunks = try generateHunks(allocator, edits, 3);
    defer freeHunks(allocator, hunks);

    try std.testing.expectEqual(@as(usize, 1), hunks.len);
    try std.testing.expectEqual(@as(u32, 1), hunks[0].old_start);
    try std.testing.expectEqual(@as(u32, 1), hunks[0].new_start);
}

test "generate hunks empty" {
    const allocator = std.testing.allocator;
    const edits: []const diff.Edit = &.{};

    const hunks = try generateHunks(allocator, edits, 3);
    defer freeHunks(allocator, hunks);

    try std.testing.expectEqual(@as(usize, 0), hunks.len);
}

test "generate hunks all equal" {
    const allocator = std.testing.allocator;

    const edits = &[_]diff.Edit{
        .{ .kind = .equal, .old_idx = 0, .new_idx = 0, .old_line = "a", .new_line = "a" },
        .{ .kind = .equal, .old_idx = 1, .new_idx = 1, .old_line = "b", .new_line = "b" },
    };

    const hunks = try generateHunks(allocator, edits, 3);
    defer freeHunks(allocator, hunks);

    try std.testing.expectEqual(@as(usize, 0), hunks.len);
}

test "generate hunks multiple separate changes" {
    const allocator = std.testing.allocator;

    var edits_list = std.ArrayListUnmanaged(diff.Edit).empty;
    defer edits_list.deinit(allocator);

    for (0..20) |i| {
        try edits_list.append(allocator, .{
            .kind = .equal,
            .old_idx = i,
            .new_idx = i,
            .old_line = "line",
            .new_line = "line",
        });
    }

    edits_list.items[5].kind = .delete;
    edits_list.items[5].new_idx = null;
    edits_list.items[5].new_line = null;

    edits_list.items[15].kind = .insert;
    edits_list.items[15].old_idx = null;
    edits_list.items[15].old_line = null;

    const hunks = try generateHunks(allocator, edits_list.items, 2);
    defer freeHunks(allocator, hunks);

    try std.testing.expectEqual(@as(usize, 2), hunks.len);
}
