local base_gui = {}

local gui = require("__flib__.gui")

local search_pane = require("scripts.gui.panes.search")

local content_panes = {}

gui.add_templates{
  frame_action_button = {type="sprite-button", style="rb_frame_action_button", mouse_button_filter={"left"}}
}

gui.add_handlers{
  base = {
    close_button = {
      on_gui_click = function(e)
        gui.handlers.base.window.on_gui_closed(e)
        -- base_gui.destroy(game.get_player(e.player_index), global.players(e.player_index))
      end
    },
    window = {
      on_gui_closed = function(e)
        base_gui.destroy(game.get_player(e.player_index), global.players[e.player_index])
      end
    }
  }
}

function base_gui.create(player, player_table)
  local gui_data = gui.build(player.gui.screen, {
    {type="frame", style="dialog_frame", handlers="base.window", save_as="base.window", children={
      -- titlebar
      {type="flow", children={
        -- TODO tooltips
        {template="frame_action_button", sprite="rb_nav_backward_white", hovered_sprite="rb_nav_backward_black", clicked_sprite="rb_nav_backward_black",
          mods={enabled=false}},
        {template="frame_action_button", sprite="rb_nav_forward_white", hovered_sprite="rb_nav_forward_black", clicked_sprite="rb_nav_forward_black",
          mods={enabled=false}},
        {type="label", style="rb_window_title_label", caption={"mod-name.RecipeBook"}, save_as="base.title_label"},
        {type="empty-widget", style="rb_drag_handle", save_as="base.drag_handle"},
        {template="frame_action_button", sprite="rb_pin_white", hovered_sprite="rb_pin_black", clicked_sprite="rb_pin_black", tooltip={"rb-gui.keep-open"}},
        {template="frame_action_button", sprite="rb_close_white", hovered_sprite="rb_close_black", clicked_sprite="rb_close_black",
          handlers="base.close_button"}
      }}
    }}
  })

  -- screen
  player.opened = gui_data.base.window
  gui_data.base.window.force_auto_center()

  -- dragging
  gui_data.base.title_label.drag_target = gui_data.base.window
  gui_data.base.drag_handle.drag_target = gui_data.base.window

  -- shortcut
  player.set_shortcut_toggled("rb-toggle-search", true)

  player_table.gui = gui_data
end

function base_gui.destroy(player, player_table)
  gui.remove_player_filters(player.index)
  player_table.gui.base.window.destroy()
  player_table.gui = nil

  player.set_shortcut_toggled("rb-toggle-search", false)
end

return base_gui