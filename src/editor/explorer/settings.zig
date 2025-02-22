const std = @import("std");
const pixi = @import("../../pixi.zig");
const core = @import("mach-core");
const zgui = @import("zgui").MachImgui(core);
const nfd = @import("nfd");

pub fn draw() void {
    zgui.pushStyleVar2f(.{ .idx = zgui.StyleVar.frame_padding, .v = .{ 6.0 * pixi.content_scale[1], 6.0 * pixi.content_scale[1] } });
    defer zgui.popStyleVar(.{ .count = 1 });
    zgui.pushStyleColor4f(.{ .idx = zgui.StyleCol.header, .c = pixi.state.theme.highlight_secondary.toSlice() });
    defer zgui.popStyleColor(.{ .count = 1 });

    zgui.pushItemWidth(zgui.getWindowWidth() - pixi.state.settings.explorer_grip * pixi.content_scale[0]);
    if (zgui.collapsingHeader(zgui.formatZ("{s}  {s}", .{ pixi.fa.mouse, "Input" }), .{ .framed = true })) {
        zgui.pushStyleVar2f(.{ .idx = zgui.StyleVar.item_spacing, .v = .{ 3.0 * pixi.content_scale[0], 3.0 * pixi.content_scale[1] } });
        zgui.pushStyleVar2f(.{ .idx = zgui.StyleVar.frame_padding, .v = .{ 4.0 * pixi.content_scale[1], 4.0 * pixi.content_scale[1] } });
        defer zgui.popStyleVar(.{ .count = 2 });

        zgui.pushItemWidth(pixi.state.settings.explorer_width * pixi.content_scale[0] * 0.5);
        if (zgui.beginCombo("Scheme", .{ .preview_value = @tagName(pixi.state.settings.input_scheme) })) {
            defer zgui.endCombo();
            if (zgui.selectable("mouse", .{})) {
                pixi.state.settings.input_scheme = .mouse;
            }
            if (zgui.selectable("trackpad", .{})) {
                pixi.state.settings.input_scheme = .trackpad;
            }
        }

        if (pixi.state.settings.input_scheme == .trackpad) {
            _ = zgui.sliderFloat("Sensitivity", .{
                .v = &pixi.state.settings.pan_sensitivity,
                .min = 1.0,
                .max = 25.0,
                .cfmt = "%.0f",
            });
        }
        zgui.popItemWidth();
    }

    if (zgui.collapsingHeader(zgui.formatZ("{s}  {s}", .{ pixi.fa.th_list, "Layout" }), .{})) {
        zgui.pushStyleVar2f(.{ .idx = zgui.StyleVar.item_spacing, .v = .{ 3.0 * pixi.content_scale[0], 3.0 * pixi.content_scale[1] } });
        zgui.pushStyleVar2f(.{ .idx = zgui.StyleVar.frame_padding, .v = .{ 4.0 * pixi.content_scale[1], 4.0 * pixi.content_scale[1] } });
        defer zgui.popStyleVar(.{ .count = 2 });

        zgui.pushItemWidth(pixi.state.settings.explorer_width * pixi.content_scale[0] * 0.5);

        _ = zgui.sliderFloat("Info Height", .{
            .v = &pixi.state.settings.info_bar_height,
            .min = 18,
            .max = 36,
            .cfmt = "%.0f",
        });

        _ = zgui.sliderFloat("Sidebar Width", .{
            .v = &pixi.state.settings.sidebar_width,
            .min = 25,
            .max = 75,
            .cfmt = "%.0f",
        });

        _ = zgui.checkbox("Show Rulers", .{
            .v = &pixi.state.settings.show_rulers,
        });
        zgui.popItemWidth();
    }

    if (zgui.collapsingHeader(pixi.fa.sliders_h ++ " " ++ "Configuration", .{})) {
        zgui.pushStyleVar2f(.{ .idx = zgui.StyleVar.item_spacing, .v = .{ 3.0 * pixi.content_scale[0], 3.0 * pixi.content_scale[1] } });
        zgui.pushStyleVar2f(.{ .idx = zgui.StyleVar.frame_padding, .v = .{ 4.0 * pixi.content_scale[1], 4.0 * pixi.content_scale[1] } });
        defer zgui.popStyleVar(.{ .count = 2 });
        zgui.pushItemWidth(pixi.state.settings.explorer_width * pixi.content_scale[0] * 0.5);

        _ = zgui.checkbox("Dropper Auto-switch", .{
            .v = &pixi.state.settings.eyedropper_auto_switch_layer,
        });
        zgui.popItemWidth();
    }

    if (zgui.collapsingHeader(zgui.formatZ("{s}  {s}", .{ pixi.fa.paint_roller, "Style" }), .{})) {
        zgui.pushStyleVar2f(.{ .idx = zgui.StyleVar.item_spacing, .v = .{ 3.0 * pixi.content_scale[0], 3.0 * pixi.content_scale[1] } });
        zgui.pushStyleVar2f(.{ .idx = zgui.StyleVar.frame_padding, .v = .{ 4.0 * pixi.content_scale[1], 4.0 * pixi.content_scale[1] } });
        defer zgui.popStyleVar(.{ .count = 2 });

        zgui.pushStyleColor4f(.{ .idx = zgui.StyleCol.button, .c = pixi.state.theme.highlight_secondary.toSlice() });
        defer zgui.popStyleColor(.{ .count = 1 });

        zgui.pushItemWidth(zgui.getWindowWidth() * 0.7);
        if (zgui.beginCombo("Theme", .{ .preview_value = pixi.state.theme.name })) {
            defer zgui.endCombo();
            searchThemes() catch unreachable;
        }
        zgui.separator();

        _ = pixi.editor.Theme.styleColorEdit("Background", .{ .col = &pixi.state.theme.background });
        _ = pixi.editor.Theme.styleColorEdit("Foreground", .{ .col = &pixi.state.theme.foreground });
        _ = pixi.editor.Theme.styleColorEdit("Text", .{ .col = &pixi.state.theme.text });
        _ = pixi.editor.Theme.styleColorEdit("Secondary Text", .{ .col = &pixi.state.theme.text_secondary });
        _ = pixi.editor.Theme.styleColorEdit("Background Text", .{ .col = &pixi.state.theme.text_background });
        _ = pixi.editor.Theme.styleColorEdit("Primary Highlight", .{ .col = &pixi.state.theme.highlight_primary });
        _ = pixi.editor.Theme.styleColorEdit("Secondary Highlight", .{ .col = &pixi.state.theme.highlight_secondary });
        _ = pixi.editor.Theme.styleColorEdit("Primary Hover", .{ .col = &pixi.state.theme.hover_primary });
        _ = pixi.editor.Theme.styleColorEdit("Secondary Hover", .{ .col = &pixi.state.theme.hover_secondary });

        zgui.separator();
        if (zgui.button("Save As...", .{ .w = zgui.getWindowWidth() - pixi.state.settings.explorer_grip * pixi.content_scale[0] })) {
            pixi.state.popups.file_dialog_request = .{
                .state = .save,
                .type = .export_theme,
                .filter = "json",
                .initial = pixi.assets.themes,
            };
        }

        if (pixi.state.popups.file_dialog_response) |response| {
            if (response.type == .export_theme) {
                pixi.state.theme.save(response.path) catch unreachable;
            }
            nfd.freePath(response.path);
            pixi.state.popups.file_dialog_response = null;
        }

        zgui.popItemWidth();
    }
    zgui.popItemWidth();
}

fn searchThemes() !void {
    var dir_opt = std.fs.cwd().openIterableDir(pixi.assets.themes, .{ .access_sub_paths = false }) catch null;
    if (dir_opt) |*dir| {
        defer dir.close();
        var iter = dir.iterate();
        while (try iter.next()) |entry| {
            if (entry.kind == .file) {
                const ext = std.fs.path.extension(entry.name);
                if (std.mem.eql(u8, ext, ".json")) {
                    const label = try std.fmt.allocPrintZ(pixi.state.allocator, "{s}", .{entry.name});
                    defer pixi.state.allocator.free(label);
                    if (zgui.selectable(label, .{})) {
                        const abs_path = try std.fs.path.joinZ(pixi.state.allocator, &.{ pixi.assets.themes, entry.name });
                        defer pixi.state.allocator.free(abs_path);
                        pixi.state.theme = try pixi.editor.Theme.loadFromFile(abs_path);
                    }
                }
            }
        }
    }
}
