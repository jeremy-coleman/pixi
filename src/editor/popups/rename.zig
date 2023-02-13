const std = @import("std");
const pixi = @import("pixi");
const zgui = @import("zgui");

pub fn draw() void {
    if (pixi.state.popups.rename) {
        zgui.openPopup("Rename...", .{});
    } else return;

    const popup_width = 350 * pixi.state.window.scale[0];
    const popup_height = 120 * pixi.state.window.scale[1];

    const window_size = pixi.state.window.size * pixi.state.window.scale;
    const window_center: [2]f32 = .{ window_size[0] / 2.0, window_size[1] / 2.0 };

    zgui.setNextWindowPos(.{
        .x = window_center[0] - popup_width / 2.0,
        .y = window_center[1] - popup_height / 2.0,
    });
    zgui.setNextWindowSize(.{
        .w = popup_width,
        .h = popup_height,
    });

    if (zgui.beginPopupModal("Rename...", .{
        .popen = &pixi.state.popups.rename,
        .flags = .{
            .no_resize = true,
            .no_collapse = true,
        },
    })) {
        defer zgui.endPopup();

        const base_name = std.fs.path.basename(pixi.state.popups.rename_path[0..]);
        var base_index: usize = 0;
        if (std.mem.indexOf(u8, pixi.state.popups.rename_path[0..], base_name)) |index| {
            base_index = index;
        }

        if (zgui.inputText("Name", .{
            .buf = pixi.state.popups.rename_path[base_index..],
            .flags = .{
                .chars_no_blank = true,
                .auto_select_all = true,
                .enter_returns_true = true,
            },
        }) or zgui.button("Ok", .{})) {
            const old_path = std.mem.trimRight(u8, pixi.state.popups.rename_old_path[0..], "\u{0}");
            const new_path = std.mem.trimRight(u8, pixi.state.popups.rename_path[0..], "\u{0}");
            std.fs.renameAbsolute(old_path[0..], new_path[0..]) catch unreachable;
            // TODO: Ensure open file paths get renamed as well.
            pixi.state.popups.rename = false;
        }
        zgui.sameLine(.{});
        if (zgui.button("Cancel", .{})) {
            pixi.state.popups.rename = false;
        }
    }
}
