const std = @import("std");
const pixi = @import("../../pixi.zig");
const core = @import("mach-core");
const zgui = @import("zgui").MachImgui(core);
const editor = pixi.editor;
const nfd = @import("nfd");

pub const menu = @import("menu.zig");
pub const rulers = @import("rulers.zig");
pub const canvas = @import("canvas.zig");
pub const canvas_pack = @import("canvas_pack.zig");

pub const flipbook = @import("flipbook/flipbook.zig");
pub const infobar = @import("infobar.zig");

pub fn draw() void {
    zgui.pushStyleVar1f(.{ .idx = zgui.StyleVar.window_rounding, .v = 0.0 });
    defer zgui.popStyleVar(.{ .count = 1 });
    zgui.setNextWindowPos(.{
        .x = (pixi.state.settings.sidebar_width + pixi.state.settings.explorer_width) * pixi.content_scale[0],
        .y = 0,
        .cond = .always,
    });
    zgui.setNextWindowSize(.{
        .w = pixi.framebuffer_size[0] - ((pixi.state.settings.explorer_width + pixi.state.settings.sidebar_width) * pixi.content_scale[0]),
        .h = pixi.framebuffer_size[1] + 5.0,
    });

    zgui.pushStyleVar2f(.{ .idx = zgui.StyleVar.window_padding, .v = .{ 0.0, 0.0 } });
    zgui.pushStyleVar1f(.{ .idx = zgui.StyleVar.tab_rounding, .v = 0.0 });
    zgui.pushStyleVar1f(.{ .idx = zgui.StyleVar.child_border_size, .v = 1.0 });
    defer zgui.popStyleVar(.{ .count = 3 });
    if (zgui.begin("Art", .{
        .flags = .{
            .no_title_bar = true,
            .no_resize = true,
            .no_move = true,
            .no_collapse = true,
            .menu_bar = true,
        },
    })) {
        menu.draw();
        const window_height = zgui.getContentRegionAvail()[1];
        const artboard_height = if (pixi.state.open_files.items.len > 0 and pixi.state.sidebar != .pack) window_height - window_height * pixi.state.settings.flipbook_height else 0.0;

        const artboard_mouse_ratio = (pixi.state.mouse.position[1] - zgui.getCursorScreenPos()[1]) / window_height;

        zgui.pushStyleVar2f(.{ .idx = zgui.StyleVar.item_spacing, .v = .{ 0.0, 0.0 } });
        defer zgui.popStyleVar(.{ .count = 1 });
        if (zgui.beginChild("Artboard", .{
            .w = 0.0,
            .h = artboard_height,
            .border = false,
            .flags = .{},
        })) {
            if (pixi.state.sidebar == .pack) {
                if (zgui.beginTabBar("PackedTextures", .{
                    .reorderable = true,
                    .auto_select_new_tabs = false,
                    .no_close_with_middle_mouse_button = true,
                })) {
                    defer zgui.endTabBar();

                    if (zgui.beginTabItem("Atlas.Diffusemap", .{
                        .p_open = null,
                        .flags = .{},
                    })) {
                        defer zgui.endTabItem();
                        canvas_pack.draw(.diffusemap);
                    }

                    if (zgui.beginTabItem("Atlas.Heightmap", .{
                        .p_open = null,
                        .flags = .{},
                    })) {
                        defer zgui.endTabItem();
                        canvas_pack.draw(.heightmap);
                    }
                }
            } else if (pixi.state.open_files.items.len > 0) {
                if (zgui.beginTabBar("Files", .{
                    .reorderable = true,
                    .auto_select_new_tabs = true,
                })) {
                    defer zgui.endTabBar();

                    for (pixi.state.open_files.items, 0..) |file, i| {
                        var open: bool = true;

                        const file_name = std.fs.path.basename(file.path);

                        zgui.pushIntId(@as(i32, @intCast(i)));
                        defer zgui.popId();

                        const label = zgui.formatZ(" {s}  {s} ", .{ pixi.fa.file_powerpoint, file_name });

                        if (zgui.beginTabItem(label, .{
                            .p_open = &open,
                            .flags = .{
                                .set_selected = pixi.state.open_file_index == i,
                                .unsaved_document = file.dirty() or file.saving,
                            },
                        })) {
                            zgui.endTabItem();
                        }
                        if (!open and !file.saving) {
                            pixi.editor.closeFile(i) catch unreachable;
                        }

                        if (zgui.isItemClicked(.left)) {
                            pixi.editor.setActiveFile(i);
                        }

                        if (zgui.isItemHovered(.{ .delay_short = true })) {
                            zgui.pushStyleVar2f(.{ .idx = zgui.StyleVar.window_padding, .v = .{ 4.0 * pixi.content_scale[0], 4.0 * pixi.content_scale[1] } });
                            defer zgui.popStyleVar(.{ .count = 1 });
                            if (zgui.beginTooltip()) {
                                defer zgui.endTooltip();
                                zgui.textColored(pixi.state.theme.text_secondary.toSlice(), "{s}", .{file.path});
                            }
                        }
                    }

                    // Add ruler child windows to build layout, but wait to draw to them until camera has been updated.
                    if (pixi.state.settings.show_rulers) {
                        if (zgui.beginChild("TopRuler", .{
                            .h = zgui.getTextLineHeightWithSpacing() * 1.5,
                            .border = false,
                            .flags = .{
                                .no_scrollbar = true,
                            },
                        })) {}
                        zgui.endChild();

                        if (zgui.beginChild("SideRuler", .{
                            .h = -1.0,
                            .w = zgui.getTextLineHeightWithSpacing() * 1.5,
                            .border = false,
                            .flags = .{
                                .no_scrollbar = true,
                            },
                        })) {}
                        zgui.endChild();
                        zgui.sameLine(.{});
                    }

                    var flags: zgui.WindowFlags = .{
                        .horizontal_scrollbar = true,
                    };

                    if (pixi.editor.getFile(pixi.state.open_file_index)) |file| {
                        if (zgui.beginChild(file.path, .{
                            .h = 0.0,
                            .w = 0.0,
                            .border = false,
                            .flags = flags,
                        })) {
                            canvas.draw(file);
                        }
                        zgui.endChild();

                        // Now add to ruler children windows, since we have updated the camera.
                        if (pixi.state.settings.show_rulers) {
                            rulers.draw(file);
                        }
                    }
                }
            } else {
                zgui.pushStyleColor4f(.{ .idx = zgui.StyleCol.button, .c = pixi.state.theme.background.toSlice() });
                zgui.pushStyleColor4f(.{ .idx = zgui.StyleCol.button_active, .c = pixi.state.theme.background.toSlice() });
                zgui.pushStyleColor4f(.{ .idx = zgui.StyleCol.button_hovered, .c = pixi.state.theme.foreground.toSlice() });
                zgui.pushStyleColor4f(.{ .idx = zgui.StyleCol.text, .c = pixi.state.theme.text_background.toSlice() });
                defer zgui.popStyleColor(.{ .count = 4 });
                { // Draw semi-transparent logo
                    const w = @as(f32, @floatFromInt((pixi.state.background_logo.image.width) / 4)) * pixi.content_scale[0];
                    const h = @as(f32, @floatFromInt((pixi.state.background_logo.image.height) / 4)) * pixi.content_scale[1];
                    const center: [2]f32 = .{ zgui.getWindowWidth() / 2.0, zgui.getWindowHeight() / 2.0 };

                    zgui.setCursorPosX(center[0] - w / 2.0);
                    zgui.setCursorPosY(center[1] - h / 2.0);
                    zgui.image(pixi.state.background_logo.view_handle, .{
                        .w = w,
                        .h = h,
                        .tint_col = .{ 1.0, 1.0, 1.0, 0.25 },
                    });
                }
                { // Draw `Open Folder` button
                    const text: [:0]const u8 = "  Open Folder  " ++ pixi.fa.folder_open ++ " ";
                    const size = zgui.calcTextSize(text, .{});
                    zgui.setCursorPosX((zgui.getWindowWidth() - size[0]) / 2);
                    if (zgui.button(text, .{})) {
                        pixi.state.popups.file_dialog_request = .{
                            .state = .folder,
                            .type = .project,
                        };
                    }
                    if (pixi.state.popups.file_dialog_response) |response| {
                        if (response.type == .project) {
                            pixi.editor.setProjectFolder(response.path);
                            nfd.freePath(response.path);
                            pixi.state.popups.file_dialog_response = null;
                        }
                    }
                }
            }
        }

        {
            // Draw a shadow fading from bottom to top
            const pos = zgui.getWindowPos();
            const height = zgui.getWindowHeight();
            const width = zgui.getWindowWidth();

            const draw_list = zgui.getWindowDrawList();
            draw_list.addRectFilledMultiColor(.{
                .pmin = .{ pos[0], (pos[1] + height) - 18 * pixi.content_scale[1] },
                .pmax = .{ pos[0] + width, pos[1] + height },
                .col_upr_left = 0x0,
                .col_upr_right = 0x0,
                .col_bot_left = 0x15000000,
                .col_bot_right = 0x15000000,
            });
        }

        zgui.endChild();

        if (pixi.state.sidebar != .pack) {
            if (pixi.state.open_files.items.len > 0) {
                const flipbook_height = window_height - artboard_height - pixi.state.settings.info_bar_height * pixi.content_scale[1];
                zgui.separator();

                if (zgui.beginChild("Flipbook", .{
                    .w = 0.0,
                    .h = flipbook_height,
                    .border = false,
                    .flags = .{
                        .menu_bar = if (pixi.editor.getFile(pixi.state.open_file_index)) |_| true else false,
                    },
                })) {
                    if (pixi.editor.getFile(pixi.state.open_file_index)) |file| {
                        flipbook.menu.draw(file, artboard_mouse_ratio);

                        if (zgui.beginChild("FlipbookCanvas", .{})) {
                            flipbook.canvas.draw(file);
                        }
                        zgui.endChild();
                    }
                }
                zgui.endChild();
                if (pixi.state.project_folder != null or pixi.state.open_files.items.len > 0) {
                    zgui.pushStyleColor4f(.{ .idx = zgui.StyleCol.child_bg, .c = pixi.state.theme.highlight_primary.toSlice() });
                    defer zgui.popStyleColor(.{ .count = 1 });
                    if (zgui.beginChild("InfoBar", .{})) {
                        infobar.draw();
                    }
                    zgui.endChild();
                }
            }
        }

        {
            const pos = zgui.getWindowPos();
            const height = zgui.getWindowHeight();

            const draw_list = zgui.getWindowDrawList();

            // Draw a shadow fading from left to right
            draw_list.addRectFilledMultiColor(.{
                .pmin = pos,
                .pmax = .{ pos[0] + 18 * pixi.content_scale[0], height + pos[1] },
                .col_upr_left = 0x15000000,
                .col_upr_right = 0x0,
                .col_bot_left = 0x15000000,
                .col_bot_right = 0x0,
            });
        }
    }
    zgui.end();
}
