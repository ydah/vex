//! Color scheme module
//! Modern color theme based on Tokyo Night

const std = @import("std");

pub const Theme = struct {
    bg: []const u8,
    fg: []const u8,
    addition_fg: []const u8,
    addition_bg: []const u8,
    deletion_fg: []const u8,
    deletion_bg: []const u8,
    modification_fg: []const u8,
    modification_bg: []const u8,
    line_number: []const u8,
    comment: []const u8,
    keyword: []const u8,
    string: []const u8,
    function_color: []const u8,
    type_color: []const u8,
    hunk_header: []const u8,
    border: []const u8,
};

pub const Color = struct {
    pub const reset = "\x1b[0m";
    pub const bold = "\x1b[1m";
    pub const dim = "\x1b[2m";
    pub const italic = "\x1b[3m";
    pub const underline = "\x1b[4m";
    pub const reverse = "\x1b[7m";

    pub fn fg256(code: u8) [11]u8 {
        var buf: [11]u8 = undefined;
        _ = std.fmt.bufPrint(&buf, "\x1b[38;5;{d}m", .{code}) catch {};
        return buf;
    }

    pub fn bg256(code: u8) [11]u8 {
        var buf: [11]u8 = undefined;
        _ = std.fmt.bufPrint(&buf, "\x1b[48;5;{d}m", .{code}) catch {};
        return buf;
    }

    pub fn fgRgb(buf: *[19]u8, r: u8, g: u8, b: u8) []const u8 {
        return std.fmt.bufPrint(buf, "\x1b[38;2;{d};{d};{d}m", .{ r, g, b }) catch "";
    }

    pub fn bgRgb(buf: *[19]u8, r: u8, g: u8, b: u8) []const u8 {
        return std.fmt.bufPrint(buf, "\x1b[48;2;{d};{d};{d}m", .{ r, g, b }) catch "";
    }
};

pub const themes = struct {
    pub const tokyo_night = Theme{
        .bg = "\x1b[48;2;26;27;38m",
        .fg = "\x1b[38;2;192;202;245m",
        .addition_fg = "\x1b[38;2;158;206;106m",
        .addition_bg = "\x1b[48;2;42;74;62m",
        .deletion_fg = "\x1b[38;2;247;118;142m",
        .deletion_bg = "\x1b[48;2;74;42;62m",
        .modification_fg = "\x1b[38;2;122;162;247m",
        .modification_bg = "\x1b[48;2;42;58;94m",
        .line_number = "\x1b[38;2;86;95;137m",
        .comment = "\x1b[38;2;86;95;137m",
        .keyword = "\x1b[38;2;187;154;247m",
        .string = "\x1b[38;2;158;206;106m",
        .function_color = "\x1b[38;2;122;162;247m",
        .type_color = "\x1b[38;2;42;195;222m",
        .hunk_header = "\x1b[38;2;122;162;247m",
        .border = "\x1b[38;2;86;95;137m",
    };

    pub const github_dark = Theme{
        .bg = "\x1b[48;2;13;17;23m",
        .fg = "\x1b[38;2;201;209;217m",
        .addition_fg = "\x1b[38;2;63;185;80m",
        .addition_bg = "\x1b[48;2;35;134;54m",
        .deletion_fg = "\x1b[38;2;248;81;73m",
        .deletion_bg = "\x1b[48;2;164;14;38m",
        .modification_fg = "\x1b[38;2;210;153;34m",
        .modification_bg = "\x1b[48;2;93;69;12m",
        .line_number = "\x1b[38;2;110;118;129m",
        .comment = "\x1b[38;2;139;148;158m",
        .keyword = "\x1b[38;2;255;123;114m",
        .string = "\x1b[38;2;165;214;255m",
        .function_color = "\x1b[38;2;210;168;255m",
        .type_color = "\x1b[38;2;255;166;87m",
        .hunk_header = "\x1b[38;2;121;192;255m",
        .border = "\x1b[38;2;48;54;61m",
    };

    pub const monokai = Theme{
        .bg = "\x1b[48;2;39;40;34m",
        .fg = "\x1b[38;2;248;248;242m",
        .addition_fg = "\x1b[38;2;166;226;46m",
        .addition_bg = "\x1b[48;2;50;70;30m",
        .deletion_fg = "\x1b[38;2;249;38;114m",
        .deletion_bg = "\x1b[48;2;80;30;40m",
        .modification_fg = "\x1b[38;2;102;217;239m",
        .modification_bg = "\x1b[48;2;30;60;70m",
        .line_number = "\x1b[38;2;117;113;94m",
        .comment = "\x1b[38;2;117;113;94m",
        .keyword = "\x1b[38;2;249;38;114m",
        .string = "\x1b[38;2;230;219;116m",
        .function_color = "\x1b[38;2;166;226;46m",
        .type_color = "\x1b[38;2;102;217;239m",
        .hunk_header = "\x1b[38;2;174;129;255m",
        .border = "\x1b[38;2;117;113;94m",
    };

    pub const default = tokyo_night;
};

test "color codes" {
    const fg = Color.fg256(196);
    try std.testing.expect(fg.len > 0);

    const bg = Color.bg256(46);
    try std.testing.expect(bg.len > 0);
}
