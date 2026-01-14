//! Edit operations module
//! Accept left/right and merge operations

const std = @import("std");
const Allocator = std.mem.Allocator;
const buffer = @import("buffer.zig");
const hunks_mod = @import("../core/hunks.zig");

pub const MergeResult = struct {
    content: []u8,
    allocator: Allocator,

    pub fn deinit(self: *MergeResult) void {
        self.allocator.free(self.content);
    }
};

pub const MergeChoice = enum {
    left,
    right,
    both,
    manual,
};

pub fn acceptLeft(
    allocator: Allocator,
    hunk: hunks_mod.Hunk,
) !MergeResult {
    var result = std.ArrayListUnmanaged(u8).empty;
    errdefer result.deinit(allocator);

    for (hunk.changes) |change| {
        switch (change.kind) {
            .context, .deletion => {
                try result.appendSlice(allocator, change.content);
                try result.append(allocator, '\n');
            },
            .addition => {},
        }
    }

    return MergeResult{
        .content = try result.toOwnedSlice(allocator),
        .allocator = allocator,
    };
}

pub fn acceptRight(
    allocator: Allocator,
    hunk: hunks_mod.Hunk,
) !MergeResult {
    var result = std.ArrayListUnmanaged(u8).empty;
    errdefer result.deinit(allocator);

    for (hunk.changes) |change| {
        switch (change.kind) {
            .context, .addition => {
                try result.appendSlice(allocator, change.content);
                try result.append(allocator, '\n');
            },
            .deletion => {},
        }
    }

    return MergeResult{
        .content = try result.toOwnedSlice(allocator),
        .allocator = allocator,
    };
}

pub fn acceptBoth(
    allocator: Allocator,
    hunk: hunks_mod.Hunk,
) !MergeResult {
    var result = std.ArrayListUnmanaged(u8).empty;
    errdefer result.deinit(allocator);

    for (hunk.changes) |change| {
        try result.appendSlice(allocator, change.content);
        try result.append(allocator, '\n');
    }

    return MergeResult{
        .content = try result.toOwnedSlice(allocator),
        .allocator = allocator,
    };
}

pub fn applyMergeToBuffer(
    buf: *buffer.Buffer,
    merge_result: MergeResult,
    start_line: usize,
    line_count: usize,
) !void {
    var i: usize = 0;
    while (i < line_count and start_line < buf.lineCount()) : (i += 1) {
        var line = &buf.lines.items[start_line];
        line.deinit();
        _ = buf.lines.orderedRemove(start_line);
    }

    var offset: usize = 0;
    var line_start: usize = 0;
    var insert_idx: usize = start_line;

    while (offset < merge_result.content.len) : (offset += 1) {
        if (merge_result.content[offset] == '\n') {
            const line = try buffer.Line.init(
                buf.allocator,
                merge_result.content[line_start..offset],
            );
            try buf.lines.insert(buf.allocator, insert_idx, line);
            insert_idx += 1;
            line_start = offset + 1;
        }
    }

    if (line_start < merge_result.content.len) {
        const line = try buffer.Line.init(
            buf.allocator,
            merge_result.content[line_start..],
        );
        try buf.lines.insert(buf.allocator, insert_idx, line);
    }

    buf.modified = true;
}

test "accept left" {
    const allocator = std.testing.allocator;

    const changes = &[_]hunks_mod.Change{
        .{ .kind = .context, .content = "unchanged", .old_line_num = 1, .new_line_num = 1 },
        .{ .kind = .deletion, .content = "old line", .old_line_num = 2, .new_line_num = null },
        .{ .kind = .addition, .content = "new line", .old_line_num = null, .new_line_num = 2 },
    };

    const hunk = hunks_mod.Hunk{
        .old_start = 1,
        .old_count = 2,
        .new_start = 1,
        .new_count = 2,
        .changes = @constCast(changes),
    };

    var result = try acceptLeft(allocator, hunk);
    defer result.deinit();

    try std.testing.expect(std.mem.indexOf(u8, result.content, "unchanged") != null);
    try std.testing.expect(std.mem.indexOf(u8, result.content, "old line") != null);
    try std.testing.expect(std.mem.indexOf(u8, result.content, "new line") == null);
}

test "accept right" {
    const allocator = std.testing.allocator;

    const changes = &[_]hunks_mod.Change{
        .{ .kind = .context, .content = "unchanged", .old_line_num = 1, .new_line_num = 1 },
        .{ .kind = .deletion, .content = "old line", .old_line_num = 2, .new_line_num = null },
        .{ .kind = .addition, .content = "new line", .old_line_num = null, .new_line_num = 2 },
    };

    const hunk = hunks_mod.Hunk{
        .old_start = 1,
        .old_count = 2,
        .new_start = 1,
        .new_count = 2,
        .changes = @constCast(changes),
    };

    var result = try acceptRight(allocator, hunk);
    defer result.deinit();

    try std.testing.expect(std.mem.indexOf(u8, result.content, "unchanged") != null);
    try std.testing.expect(std.mem.indexOf(u8, result.content, "old line") == null);
    try std.testing.expect(std.mem.indexOf(u8, result.content, "new line") != null);
}
