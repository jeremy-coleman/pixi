const std = @import("std");
const zgui = @import("zgui");
const pixi = @import("pixi");
const settings = pixi.settings;
const editor = pixi.editor;

pub var hover_timer: f32 = 0.0;
pub var hover_label: [:0]const u8 = undefined;

pub fn draw() void {
    zgui.pushStyleVar1f(.{ .idx = zgui.StyleVar.window_rounding, .v = 0.0 });
    defer zgui.popStyleVar(.{ .count = 1 });
    zgui.setNextWindowPos(.{
        .x = (settings.sidebar_width + settings.explorer_width) * pixi.state.window.scale[0],
        .y = 0,
        .cond = .always,
    });
    zgui.setNextWindowSize(.{
        .w = (pixi.state.window.size[0] - settings.explorer_width - settings.sidebar_width) * pixi.state.window.scale[0],
        .h = pixi.state.window.size[1] * pixi.state.window.scale[1] + 5.0,
    });

    zgui.pushStyleVar2f(.{ .idx = zgui.StyleVar.window_padding, .v = .{ 0.0, 0.0 } });
    zgui.pushStyleVar1f(.{ .idx = zgui.StyleVar.tab_rounding, .v = 0.0 });
    zgui.pushStyleVar1f(.{ .idx = zgui.StyleVar.child_border_size, .v = 0.0 });
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
        editor.menu.draw();

        if (zgui.beginChild("Canvas", .{
            .w = 0.0,
            .h = pixi.state.window.size[1] / 1.5 * pixi.state.window.scale[1],
            .border = false,
            .flags = .{},
        })) {
            defer zgui.endChild();
            if (pixi.state.open_files.items.len > 0) {
                if (zgui.beginTabBar("Files", .{
                    .reorderable = true,
                    .auto_select_new_tabs = true,
                })) {
                    defer zgui.endTabBar();

                    for (pixi.state.open_files.items) |file, i| {
                        var open: bool = true;

                        const file_name = std.fs.path.basename(file.path);

                        zgui.pushIntId(@intCast(i32, i));
                        defer zgui.popId();

                        const label = zgui.formatZ("  {s}  {s} ", .{ pixi.fa.file_powerpoint, file_name });

                        if (zgui.beginTabItem(label, .{
                            .p_open = &open,
                            .flags = .{
                                .set_selected = pixi.state.open_file_index == i,
                                .unsaved_document = file.dirty,
                            },
                        })) {
                            defer zgui.endTabItem();
                        }
                        if (zgui.isItemClicked(.left)) {
                            pixi.editor.setActiveFile(i);
                        }
                        if (zgui.isItemHovered(.{})) {
                            if (std.mem.eql(u8, label, hover_label)) {
                                hover_timer += pixi.state.gctx.stats.delta_time;
                            } else {
                                hover_label = label;
                                hover_timer = 0.0;
                            }

                            if (hover_timer >= 1.0) {
                                zgui.beginTooltip();
                                defer zgui.endTooltip();
                                zgui.textColored(pixi.state.style.text_secondary.toSlice(), "{s}", .{file.path});
                            }
                        }

                        if (!open) {
                            pixi.editor.closeFile(i) catch unreachable;
                        }
                    }
                    // zgui.pushStyleColor4f(.{ .idx = zgui.StyleCol.border, .c = pixi.state.style.foreground.toSlice() });
                    // defer zgui.popStyleColor(.{ .count = 1 });
                    if (pixi.settings.show_rulers) {
                        if (zgui.beginChild("TopRuler", .{
                            .h = zgui.getTextLineHeightWithSpacing(),
                            .border = false,
                            .flags = .{
                                .no_scrollbar = true,
                            },
                        })) {}
                        zgui.endChild();

                        if (zgui.beginChild("SideRuler", .{
                            .h = -1.0,
                            .w = zgui.getTextLineHeightWithSpacing(),
                            .border = false,
                            .flags = .{
                                .no_scrollbar = true,
                            },
                        })) {}
                        zgui.endChild();
                        zgui.sameLine(.{});
                    }
                    if (zgui.beginChild("Canvas", .{
                        .h = -1.0,
                        .w = -1.0,
                        .border = false,
                        .flags = .{
                            .no_scrollbar = true,
                        },
                    })) {}
                    zgui.endChild();
                }
            } else {
                const w = @intToFloat(f32, (pixi.state.background_logo.width) / 4) * pixi.state.window.scale[0];
                const h = @intToFloat(f32, (pixi.state.background_logo.height) / 4) * pixi.state.window.scale[1];
                zgui.setCursorPosX((zgui.getWindowWidth() - w) / 2);
                zgui.setCursorPosY((zgui.getWindowHeight() - h) / 2);
                zgui.image(pixi.state.gctx.lookupResource(pixi.state.background_logo.view_handle).?, .{
                    .w = w,
                    .h = h,
                    .tint_col = .{ 1.0, 1.0, 1.0, 0.25 },
                });
                const text = zgui.formatZ("Open Folder    {s}  ", .{pixi.fa.folder_open});
                const size = zgui.calcTextSize(text, .{});
                zgui.setCursorPosX((zgui.getWindowWidth() - size[0]) / 2);
                zgui.textColored(pixi.state.style.text_background.toSlice(), "Open Folder    {s}  ", .{pixi.fa.folder_open});
            }
        }
        zgui.separator();
        if (zgui.beginChild("Flipbook", .{
            .w = 0.0,
            .h = zgui.getContentRegionAvail()[1] - pixi.settings.info_bar_height * pixi.state.window.scale[1],
            .border = false,
            .flags = .{},
        })) {
            zgui.endChild();
        }

        zgui.pushStyleColor4f(.{ .idx = zgui.StyleCol.child_bg, .c = pixi.state.style.highlight_primary.toSlice() });
        defer zgui.popStyleColor(.{ .count = 1 });
        if (zgui.beginChild("InfoBar", .{})) {
            pixi.editor.infobar.draw();
            zgui.endChild();
        }
    }
    zgui.end();
}
