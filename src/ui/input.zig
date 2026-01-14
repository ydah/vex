//! Keyboard input handling module
//! Vim-style navigation and keybindings

const std = @import("std");

pub const Action = enum {
    none,
    quit,
    scroll_up,
    scroll_down,
    page_up,
    page_down,
    next_hunk,
    prev_hunk,
    toggle_mode,
    accept_left,
    accept_right,
    start_edit,
    search,
    help,
};

pub const KeyBinding = struct {
    key: u8,
    action: Action,
    description: []const u8,
};

pub const default_bindings = [_]KeyBinding{
    .{ .key = 'q', .action = .quit, .description = "Quit" },
    .{ .key = 'j', .action = .scroll_down, .description = "Scroll down" },
    .{ .key = 'k', .action = .scroll_up, .description = "Scroll up" },
    .{ .key = 'n', .action = .next_hunk, .description = "Next hunk" },
    .{ .key = 'N', .action = .prev_hunk, .description = "Previous hunk" },
    .{ .key = '\t', .action = .toggle_mode, .description = "Toggle view mode" },
    .{ .key = 'a', .action = .accept_left, .description = "Accept left side" },
    .{ .key = 'd', .action = .accept_right, .description = "Accept right side" },
    .{ .key = 'e', .action = .start_edit, .description = "Start editing" },
    .{ .key = '/', .action = .search, .description = "Search" },
    .{ .key = '?', .action = .help, .description = "Show help" },
    .{ .key = ' ', .action = .page_down, .description = "Page down" },
    .{ .key = 'b', .action = .page_up, .description = "Page up" },
};

pub fn getAction(key: u8) Action {
    for (default_bindings) |binding| {
        if (binding.key == key) {
            return binding.action;
        }
    }
    return .none;
}

pub fn getBindingDescription(action: Action) []const u8 {
    for (default_bindings) |binding| {
        if (binding.action == action) {
            return binding.description;
        }
    }
    return "";
}

test "get action" {
    try std.testing.expectEqual(Action.quit, getAction('q'));
    try std.testing.expectEqual(Action.scroll_down, getAction('j'));
    try std.testing.expectEqual(Action.scroll_up, getAction('k'));
    try std.testing.expectEqual(Action.none, getAction('z'));
}

test "get binding description" {
    try std.testing.expectEqualStrings("Quit", getBindingDescription(.quit));
    try std.testing.expectEqualStrings("Scroll down", getBindingDescription(.scroll_down));
}
