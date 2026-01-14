//! TUI main module
//! Main loop for interactive diff viewing

const std = @import("std");
const Allocator = std.mem.Allocator;
const terminal = @import("terminal.zig");
const renderer = @import("renderer.zig");
const colors = @import("colors.zig");
const hunks_mod = @import("../core/hunks.zig");

pub const ViewMode = enum {
    side_by_side,
    unified,
};

pub const TuiState = struct {
    scroll_offset: usize,
    selected_hunk: usize,
    mode: ViewMode,
    quit: bool,
    file1_name: []const u8,
    file2_name: []const u8,
};

pub const Tui = struct {
    allocator: Allocator,
    term: terminal.Terminal,
    render: renderer.Renderer,
    state: TuiState,
    hunks: []const hunks_mod.Hunk,

    pub fn init(
        allocator: Allocator,
        hunk_list: []const hunks_mod.Hunk,
        file1_name: []const u8,
        file2_name: []const u8,
    ) !Tui {
        var term = try terminal.Terminal.init();
        errdefer term.deinit();

        var render = try renderer.Renderer.init(allocator, &term, colors.themes.default);
        errdefer render.deinit();

        return Tui{
            .allocator = allocator,
            .term = term,
            .render = render,
            .state = TuiState{
                .scroll_offset = 0,
                .selected_hunk = 0,
                .mode = .side_by_side,
                .quit = false,
                .file1_name = file1_name,
                .file2_name = file2_name,
            },
            .hunks = hunk_list,
        };
    }

    pub fn deinit(self: *Tui) void {
        self.term.write(terminal.Escape.alt_screen_leave);
        self.term.write(terminal.Escape.cursor_show);
        self.render.deinit();
        self.term.deinit();
    }

    pub fn run(self: *Tui) void {
        try self.term.enableRawMode();
        self.term.write(terminal.Escape.alt_screen_enter);
        self.term.write(terminal.Escape.cursor_hide);

        while (!self.state.quit) {
            self.draw();
            self.handleInput();
        }
    }

    fn draw(self: *Tui) void {
        self.render.clear();

        const size = self.term.getSize();
        const content_height = size.height - 2;

        self.drawHeader();

        switch (self.state.mode) {
            .side_by_side => self.drawSideBySide(content_height),
            .unified => self.drawUnified(content_height),
        }

        self.drawStatusBar();
        self.render.flush();
    }

    fn drawHeader(self: *Tui) void {
        const size = self.term.getSize();
        const theme = self.render.theme;

        self.render.drawText(0, 0, self.state.file1_name, theme.fg);

        const mid = size.width / 2;
        self.render.drawText(mid, 0, self.state.file2_name, theme.fg);
    }

    fn drawSideBySide(self: *Tui, height: u16) void {
        const size = self.term.getSize();
        const panel_width = size.width / 2 - 1;
        const theme = self.render.theme;

        var line: u16 = 1;
        var total_lines: usize = 0;

        for (self.hunks, 0..) |hunk, hunk_idx| {
            if (line >= height) break;

            const is_selected = hunk_idx == self.state.selected_hunk;

            var buf: [64]u8 = undefined;
            const header = std.fmt.bufPrint(&buf, "@@ -{d},{d} +{d},{d} @@", .{
                hunk.old_start,
                hunk.old_count,
                hunk.new_start,
                hunk.new_count,
            }) catch continue;

            const header_fg = if (is_selected) theme.modification_fg else theme.hunk_header;
            self.render.drawText(0, line, header, header_fg);
            line += 1;

            for (hunk.changes) |change| {
                if (total_lines < self.state.scroll_offset) {
                    total_lines += 1;
                    continue;
                }
                if (line >= height) break;

                const fg = switch (change.kind) {
                    .context => theme.fg,
                    .addition => theme.addition_fg,
                    .deletion => theme.deletion_fg,
                };

                switch (change.kind) {
                    .context => {
                        self.render.drawText(0, line, change.content, fg);
                        self.render.drawText(panel_width + 1, line, change.content, fg);
                    },
                    .deletion => {
                        self.render.drawText(0, line, change.content, fg);
                    },
                    .addition => {
                        self.render.drawText(panel_width + 1, line, change.content, fg);
                    },
                }

                line += 1;
                total_lines += 1;
            }

            line += 1;
        }
    }

    fn drawUnified(self: *Tui, height: u16) void {
        const theme = self.render.theme;

        var line: u16 = 1;
        var total_lines: usize = 0;

        for (self.hunks, 0..) |hunk, hunk_idx| {
            if (line >= height) break;

            const is_selected = hunk_idx == self.state.selected_hunk;

            var buf: [64]u8 = undefined;
            const header = std.fmt.bufPrint(&buf, "@@ -{d},{d} +{d},{d} @@", .{
                hunk.old_start,
                hunk.old_count,
                hunk.new_start,
                hunk.new_count,
            }) catch continue;

            const header_fg = if (is_selected) theme.modification_fg else theme.hunk_header;
            self.render.drawText(0, line, header, header_fg);
            line += 1;

            for (hunk.changes) |change| {
                if (total_lines < self.state.scroll_offset) {
                    total_lines += 1;
                    continue;
                }
                if (line >= height) break;

                const prefix: []const u8 = switch (change.kind) {
                    .context => " ",
                    .addition => "+",
                    .deletion => "-",
                };

                const fg = switch (change.kind) {
                    .context => theme.fg,
                    .addition => theme.addition_fg,
                    .deletion => theme.deletion_fg,
                };

                self.render.drawText(0, line, prefix, fg);
                self.render.drawText(1, line, change.content, fg);

                line += 1;
                total_lines += 1;
            }

            line += 1;
        }
    }

    fn drawStatusBar(self: *Tui) void {
        const mode_str = switch (self.state.mode) {
            .side_by_side => "SIDE-BY-SIDE",
            .unified => "UNIFIED",
        };

        var buf: [128]u8 = undefined;
        const status = std.fmt.bufPrint(&buf, " {s} | Hunk {d}/{d} | j/k:scroll n/N:hunk Tab:mode q:quit", .{
            mode_str,
            self.state.selected_hunk + 1,
            self.hunks.len,
        }) catch return;

        self.render.drawStatusBar(status);
    }

    fn handleInput(self: *Tui) void {
        const key = self.term.readKey() orelse return;

        switch (key) {
            'q' => self.state.quit = true,
            'j' => {
                self.state.scroll_offset +|= 1;
            },
            'k' => {
                if (self.state.scroll_offset > 0) {
                    self.state.scroll_offset -= 1;
                }
            },
            'n' => {
                if (self.state.selected_hunk < self.hunks.len - 1) {
                    self.state.selected_hunk += 1;
                }
            },
            'N' => {
                if (self.state.selected_hunk > 0) {
                    self.state.selected_hunk -= 1;
                }
            },
            '\t' => {
                self.state.mode = switch (self.state.mode) {
                    .side_by_side => .unified,
                    .unified => .side_by_side,
                };
            },
            terminal.Key.escape => {
                if (self.term.readEscapeSequence()) |seq| {
                    switch (seq[1]) {
                        terminal.Key.arrow_up => {
                            if (self.state.scroll_offset > 0) {
                                self.state.scroll_offset -= 1;
                            }
                        },
                        terminal.Key.arrow_down => {
                            self.state.scroll_offset +|= 1;
                        },
                        else => {},
                    }
                }
            },
            else => {},
        }
    }
};

test "tui state" {
    const state = TuiState{
        .scroll_offset = 0,
        .selected_hunk = 0,
        .mode = .side_by_side,
        .quit = false,
        .file1_name = "a",
        .file2_name = "b",
    };
    try std.testing.expect(!state.quit);
}
