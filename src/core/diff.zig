//! Myers diff algorithm implementation
//! Compute the minimal edit distance between two sequences

const std = @import("std");
const Allocator = std.mem.Allocator;

pub const EditKind = enum {
    equal,
    insert,
    delete,
};

pub const Edit = struct {
    kind: EditKind,
    old_idx: ?usize,
    new_idx: ?usize,
    old_line: ?[]const u8,
    new_line: ?[]const u8,
};

pub const DiffError = error{
    OutOfMemory,
};

pub fn computeDiff(
    allocator: Allocator,
    old_lines: []const []const u8,
    new_lines: []const []const u8,
) DiffError![]Edit {
    const n = old_lines.len;
    const m = new_lines.len;

    if (n == 0 and m == 0) {
        return allocator.alloc(Edit, 0) catch return DiffError.OutOfMemory;
    }

    if (n == 0) {
        const edits = allocator.alloc(Edit, m) catch return DiffError.OutOfMemory;
        for (0..m) |j| {
            edits[j] = Edit{
                .kind = .insert,
                .old_idx = null,
                .new_idx = j,
                .old_line = null,
                .new_line = new_lines[j],
            };
        }
        return edits;
    }

    if (m == 0) {
        const edits = allocator.alloc(Edit, n) catch return DiffError.OutOfMemory;
        for (0..n) |i| {
            edits[i] = Edit{
                .kind = .delete,
                .old_idx = i,
                .new_idx = null,
                .old_line = old_lines[i],
                .new_line = null,
            };
        }
        return edits;
    }

    const trace = try computeTrace(allocator, old_lines, new_lines);
    defer {
        for (trace) |v| {
            allocator.free(v);
        }
        allocator.free(trace);
    }

    return try backtrack(allocator, old_lines, new_lines, trace);
}

fn computeTrace(
    allocator: Allocator,
    old_lines: []const []const u8,
    new_lines: []const []const u8,
) DiffError![][]isize {
    const n: isize = @intCast(old_lines.len);
    const m: isize = @intCast(new_lines.len);
    const max: usize = @intCast(n + m + 1);
    const offset: isize = @intCast(max);

    var trace: std.ArrayListUnmanaged([]isize) = .empty;
    errdefer {
        for (trace.items) |v| {
            allocator.free(v);
        }
        trace.deinit(allocator);
    }

    var v = allocator.alloc(isize, 2 * max + 1) catch return DiffError.OutOfMemory;
    @memset(v, 0);

    for (0..max) |d| {
        const d_signed: isize = @intCast(d);

        const v_copy = allocator.alloc(isize, v.len) catch return DiffError.OutOfMemory;
        @memcpy(v_copy, v);
        trace.append(allocator, v_copy) catch return DiffError.OutOfMemory;

        var k: isize = -d_signed;
        while (k <= d_signed) : (k += 2) {
            var x: isize = undefined;
            const k_idx: usize = @intCast(k + offset);

            if (k == -d_signed or (k != d_signed and v[@intCast(k - 1 + offset)] < v[@intCast(k + 1 + offset)])) {
                x = v[@intCast(k + 1 + offset)];
            } else {
                x = v[@intCast(k - 1 + offset)] + 1;
            }

            var y = x - k;

            while (x < n and y < m and
                std.mem.eql(u8, old_lines[@intCast(x)], new_lines[@intCast(y)]))
            {
                x += 1;
                y += 1;
            }

            v[k_idx] = x;

            if (x >= n and y >= m) {
                allocator.free(v);
                return trace.toOwnedSlice(allocator) catch return DiffError.OutOfMemory;
            }
        }
    }

    allocator.free(v);
    return trace.toOwnedSlice(allocator) catch return DiffError.OutOfMemory;
}

fn backtrack(
    allocator: Allocator,
    old_lines: []const []const u8,
    new_lines: []const []const u8,
    trace: []const []const isize,
) DiffError![]Edit {
    const n: isize = @intCast(old_lines.len);
    const m: isize = @intCast(new_lines.len);
    const max: isize = n + m + 1;
    const offset: isize = max;

    var edits: std.ArrayListUnmanaged(Edit) = .empty;
    errdefer edits.deinit(allocator);

    var x = n;
    var y = m;
    var d: isize = @intCast(trace.len - 1);

    while (d >= 0) : (d -= 1) {
        const v = trace[@intCast(d)];
        const k = x - y;

        var prev_k: isize = undefined;
        if (k == -d or (k != d and v[@intCast(k - 1 + offset)] < v[@intCast(k + 1 + offset)])) {
            prev_k = k + 1;
        } else {
            prev_k = k - 1;
        }

        const prev_x = v[@intCast(prev_k + offset)];
        const prev_y = prev_x - prev_k;

        while (x > prev_x and y > prev_y) {
            x -= 1;
            y -= 1;
            edits.append(allocator, Edit{
                .kind = .equal,
                .old_idx = @intCast(x),
                .new_idx = @intCast(y),
                .old_line = old_lines[@intCast(x)],
                .new_line = new_lines[@intCast(y)],
            }) catch return DiffError.OutOfMemory;
        }

        if (d > 0) {
            if (x == prev_x) {
                edits.append(allocator, Edit{
                    .kind = .insert,
                    .old_idx = null,
                    .new_idx = @intCast(prev_y),
                    .old_line = null,
                    .new_line = new_lines[@intCast(prev_y)],
                }) catch return DiffError.OutOfMemory;
            } else {
                edits.append(allocator, Edit{
                    .kind = .delete,
                    .old_idx = @intCast(prev_x),
                    .new_idx = null,
                    .old_line = old_lines[@intCast(prev_x)],
                    .new_line = null,
                }) catch return DiffError.OutOfMemory;
            }
        }

        x = prev_x;
        y = prev_y;
    }

    std.mem.reverse(Edit, edits.items);
    return edits.toOwnedSlice(allocator) catch return DiffError.OutOfMemory;
}

test "same files" {
    const allocator = std.testing.allocator;
    const lines = &[_][]const u8{ "a", "b", "c" };
    const edits = try computeDiff(allocator, lines, lines);
    defer allocator.free(edits);

    try std.testing.expectEqual(@as(usize, 3), edits.len);
    for (edits) |edit| {
        try std.testing.expectEqual(EditKind.equal, edit.kind);
    }
}

test "completely different files" {
    const allocator = std.testing.allocator;
    const old = &[_][]const u8{ "a", "b" };
    const new = &[_][]const u8{ "c", "d" };
    const edits = try computeDiff(allocator, old, new);
    defer allocator.free(edits);

    var deletes: usize = 0;
    var inserts: usize = 0;
    for (edits) |edit| {
        switch (edit.kind) {
            .delete => deletes += 1,
            .insert => inserts += 1,
            .equal => {},
        }
    }
    try std.testing.expectEqual(@as(usize, 2), deletes);
    try std.testing.expectEqual(@as(usize, 2), inserts);
}

test "one line insert" {
    const allocator = std.testing.allocator;
    const old = &[_][]const u8{ "a", "c" };
    const new = &[_][]const u8{ "a", "b", "c" };
    const edits = try computeDiff(allocator, old, new);
    defer allocator.free(edits);

    var inserts: usize = 0;
    for (edits) |edit| {
        if (edit.kind == .insert) inserts += 1;
    }
    try std.testing.expectEqual(@as(usize, 1), inserts);
}

test "one line delete" {
    const allocator = std.testing.allocator;
    const old = &[_][]const u8{ "a", "b", "c" };
    const new = &[_][]const u8{ "a", "c" };
    const edits = try computeDiff(allocator, old, new);
    defer allocator.free(edits);

    var deletes: usize = 0;
    for (edits) |edit| {
        if (edit.kind == .delete) deletes += 1;
    }
    try std.testing.expectEqual(@as(usize, 1), deletes);
}

test "empty files" {
    const allocator = std.testing.allocator;
    const empty: []const []const u8 = &.{};
    const edits = try computeDiff(allocator, empty, empty);
    defer allocator.free(edits);

    try std.testing.expectEqual(@as(usize, 0), edits.len);
}

test "empty to non-empty" {
    const allocator = std.testing.allocator;
    const empty: []const []const u8 = &.{};
    const new = &[_][]const u8{ "a", "b" };
    const edits = try computeDiff(allocator, empty, new);
    defer allocator.free(edits);

    try std.testing.expectEqual(@as(usize, 2), edits.len);
    for (edits) |edit| {
        try std.testing.expectEqual(EditKind.insert, edit.kind);
    }
}

test "non-empty to empty" {
    const allocator = std.testing.allocator;
    const old = &[_][]const u8{ "a", "b" };
    const empty: []const []const u8 = &.{};
    const edits = try computeDiff(allocator, old, empty);
    defer allocator.free(edits);

    try std.testing.expectEqual(@as(usize, 2), edits.len);
    for (edits) |edit| {
        try std.testing.expectEqual(EditKind.delete, edit.kind);
    }
}
