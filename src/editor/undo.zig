//! Undo/redo module
//! Stack management for operation history

const std = @import("std");
const Allocator = std.mem.Allocator;

pub const OperationType = enum {
    insert_char,
    delete_char,
    insert_line,
    delete_line,
    modify_line,
    merge_hunk,
};

pub const Operation = struct {
    op_type: OperationType,
    line: usize,
    col: usize,
    content: []const u8,
    allocator: Allocator,

    pub fn deinit(self: *Operation) void {
        if (self.content.len > 0) {
            self.allocator.free(self.content);
        }
    }
};

pub const UndoStack = struct {
    operations: std.ArrayListUnmanaged(Operation),
    redo_stack: std.ArrayListUnmanaged(Operation),
    allocator: Allocator,
    max_size: usize,

    pub fn init(allocator: Allocator, max_size: usize) UndoStack {
        return UndoStack{
            .operations = .empty,
            .redo_stack = .empty,
            .allocator = allocator,
            .max_size = max_size,
        };
    }

    pub fn deinit(self: *UndoStack) void {
        for (self.operations.items) |*op| {
            op.deinit();
        }
        self.operations.deinit(self.allocator);

        for (self.redo_stack.items) |*op| {
            op.deinit();
        }
        self.redo_stack.deinit(self.allocator);
    }

    pub fn push(self: *UndoStack, op: Operation) !void {
        for (self.redo_stack.items) |*redo_op| {
            redo_op.deinit();
        }
        self.redo_stack.clearRetainingCapacity();

        if (self.operations.items.len >= self.max_size) {
            var oldest = self.operations.orderedRemove(0);
            oldest.deinit();
        }

        try self.operations.append(self.allocator, op);
    }

    pub fn undo(self: *UndoStack) ?Operation {
        if (self.operations.items.len == 0) return null;

        const op = self.operations.pop();
        if (op) |o| {
            self.redo_stack.append(self.allocator, o) catch {};
        }
        return op;
    }

    pub fn redo(self: *UndoStack) ?Operation {
        if (self.redo_stack.items.len == 0) return null;

        const op = self.redo_stack.pop();
        if (op) |o| {
            self.operations.append(self.allocator, o) catch {};
        }
        return op;
    }

    pub fn canUndo(self: *UndoStack) bool {
        return self.operations.items.len > 0;
    }

    pub fn canRedo(self: *UndoStack) bool {
        return self.redo_stack.items.len > 0;
    }

    pub fn clear(self: *UndoStack) void {
        for (self.operations.items) |*op| {
            op.deinit();
        }
        self.operations.clearRetainingCapacity();

        for (self.redo_stack.items) |*op| {
            op.deinit();
        }
        self.redo_stack.clearRetainingCapacity();
    }
};

pub fn createOperation(
    allocator: Allocator,
    op_type: OperationType,
    line: usize,
    col: usize,
    content: []const u8,
) !Operation {
    const content_copy = if (content.len > 0)
        try allocator.dupe(u8, content)
    else
        "";

    return Operation{
        .op_type = op_type,
        .line = line,
        .col = col,
        .content = content_copy,
        .allocator = allocator,
    };
}

test "undo stack push and undo" {
    const allocator = std.testing.allocator;
    var stack = UndoStack.init(allocator, 100);
    defer stack.deinit();

    const op = try createOperation(allocator, .insert_char, 0, 0, "a");
    try stack.push(op);

    try std.testing.expect(stack.canUndo());
    try std.testing.expect(!stack.canRedo());

    const undone = stack.undo();
    try std.testing.expect(undone != null);
    try std.testing.expect(!stack.canUndo());
    try std.testing.expect(stack.canRedo());
}

test "undo stack redo" {
    const allocator = std.testing.allocator;
    var stack = UndoStack.init(allocator, 100);
    defer stack.deinit();

    const op = try createOperation(allocator, .insert_char, 0, 0, "a");
    try stack.push(op);

    _ = stack.undo();
    try std.testing.expect(stack.canRedo());

    const redone = stack.redo();
    try std.testing.expect(redone != null);
    try std.testing.expect(stack.canUndo());
    try std.testing.expect(!stack.canRedo());
}

test "undo stack max size" {
    const allocator = std.testing.allocator;
    var stack = UndoStack.init(allocator, 3);
    defer stack.deinit();

    var i: usize = 0;
    while (i < 5) : (i += 1) {
        const op = try createOperation(allocator, .insert_char, i, 0, "x");
        try stack.push(op);
    }

    try std.testing.expectEqual(@as(usize, 3), stack.operations.items.len);
}
