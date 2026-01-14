//! SIMD optimization module
//! Speed up newline detection and string comparisons

const std = @import("std");

pub fn countNewlines(data: []const u8) usize {
    var count: usize = 0;

    const Vector = @Vector(16, u8);
    const newline_vec: Vector = @splat('\n');

    var i: usize = 0;
    while (i + 16 <= data.len) : (i += 16) {
        const chunk: Vector = data[i..][0..16].*;
        const matches = chunk == newline_vec;
        count += @popCount(@as(u16, @bitCast(matches)));
    }

    while (i < data.len) : (i += 1) {
        if (data[i] == '\n') count += 1;
    }

    return count;
}

pub fn findNewline(data: []const u8) ?usize {
    const Vector = @Vector(16, u8);
    const newline_vec: Vector = @splat('\n');

    var i: usize = 0;
    while (i + 16 <= data.len) : (i += 16) {
        const chunk: Vector = data[i..][0..16].*;
        const matches = chunk == newline_vec;
        const mask = @as(u16, @bitCast(matches));
        if (mask != 0) {
            return i + @ctz(mask);
        }
    }

    while (i < data.len) : (i += 1) {
        if (data[i] == '\n') return i;
    }

    return null;
}

pub fn memcmpFast(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    if (a.len == 0) return true;

    const Vector = @Vector(16, u8);

    var i: usize = 0;
    while (i + 16 <= a.len) : (i += 16) {
        const chunk_a: Vector = a[i..][0..16].*;
        const chunk_b: Vector = b[i..][0..16].*;
        const matches = chunk_a == chunk_b;
        const mask = @as(u16, @bitCast(matches));
        if (mask != 0xFFFF) return false;
    }

    while (i < a.len) : (i += 1) {
        if (a[i] != b[i]) return false;
    }

    return true;
}

pub fn hashLine(line: []const u8) u64 {
    var hash: u64 = 0xcbf29ce484222325;
    for (line) |c| {
        hash ^= c;
        hash *%= 0x100000001b3;
    }
    return hash;
}

test "count newlines" {
    const data = "line1\nline2\nline3\n";
    const count = countNewlines(data);
    try std.testing.expectEqual(@as(usize, 3), count);
}

test "count newlines empty" {
    const data = "";
    const count = countNewlines(data);
    try std.testing.expectEqual(@as(usize, 0), count);
}

test "find newline" {
    const data = "hello\nworld";
    const pos = findNewline(data);
    try std.testing.expectEqual(@as(?usize, 5), pos);
}

test "find newline not found" {
    const data = "no newline here";
    const pos = findNewline(data);
    try std.testing.expectEqual(@as(?usize, null), pos);
}

test "memcmp fast equal" {
    const a = "hello world";
    const b = "hello world";
    try std.testing.expect(memcmpFast(a, b));
}

test "memcmp fast not equal" {
    const a = "hello world";
    const b = "hello worLd";
    try std.testing.expect(!memcmpFast(a, b));
}

test "hash line" {
    const line = "test line";
    const hash1 = hashLine(line);
    const hash2 = hashLine(line);
    try std.testing.expectEqual(hash1, hash2);

    const different = "different";
    const hash3 = hashLine(different);
    try std.testing.expect(hash1 != hash3);
}
