local gui = require("__flib__.gui-beta")
local util = require "scripts.util"

local statistics_page = {}

local function get_statistics_categories(player_index)
  return global.players[player_index].statistics.categories
end

local function get_stat_value_string(stat)
  local prefix = stat.prefix or ""
  local suffix = stat.suffix or ""

  return prefix..stat.value..suffix
end

function statistics_page.build(player_index)
  local output = {}

  --auto-generated from statisitics table
  for category_name, stat_category in pairs(get_statistics_categories(player_index)) do
    local append = false


    local category_output = (
      {
        type = "frame",
        style = "rb_statistics_category_frame",
        direction = "vertical",
        visible = false,
        ref = {"statistics", "frame", category_name},
        children = {
          {type = "label", style = "caption_label", caption = {"rb-gui."..category_name}}
      }}
    )
    for name, data in pairs(stat_category) do
      append = true

      category_output.children[#category_output.children+1] = {
        type = "label",
        caption = {"rb-gui.statistics-"..name, get_stat_value_string(data)},
        --tooltip = data.has_tooltip and {"rb-gui.statistics-"..name.."-tooltip"} or nil,
        ref = {"statistics", category_name.."/"..name},
      }
    end

    if append then
      output[#output+1] = category_output
    end
  end

  return {
    type = "frame",
    style = "inner_frame_in_outer_frame",
    direction = "vertical",
    visible = false,
    ref = {"statistics", "window"},
    children = {
      {type = "flow", style = "flib_titlebar_flow", ref = {"statistics", "titlebar_flow"}, children = {
        {type = "label", style = "frame_title", caption = {"rb-gui.statistics"}, ignored_by_interaction = true},
        {type = "empty-widget", style = "flib_dialog_titlebar_drag_handle", ignored_by_interaction = true},
        {
          type = "sprite-button",
          style = "frame_action_button",
          sprite = "rb_pin_white",
          hovered_sprite = "rb_pin_black",
          clicked_sprite = "rb_pin_black",
          tooltip = {"rb-gui.statistics-refresh"},
          mouse_button_filter = {"left"},
          ref = {"base", "titlebar_statistics", "reload_button"},
          actions = {
            on_click = {gui = "main", action = "reload_statistics"}
          }
        },
      }},
      {type = "frame", style = "inside_shallow_frame",  children = {
        {
          type = "scroll-pane",
          style = "rb_settings_content_scroll_pane",
          direction = "vertical",
          ref = { "statistics", "scroll_pane"},
          children = {
            {type = "frame", style = "rb_statistics_category_frame", direction = "vertical", visible = true, ref = {"statistics", "frame", "dirty_info"}, children = {
              {type = "label", style = "caption_label", caption = {"rb-gui.statistics-dirty"}, tooltip = {"rb-gui.statistics-dirty-tooltip"} }
            }},
            {
              type = "scroll-pane",
              style = "rb_settings_content_scroll_pane",
              direction = "vertical",
              ref = { "statistics", "scroll_pane"},
              children = output
            }
          }
        }
      }}
    }
  }
end

function statistics_page.init()
  return {
    open = false
  }
end

function statistics_page.set_dirty(player_index)
  global.players[player_index].statistics.is_dirty = true
end

function statistics_page.update(player_index, gui_data)
  local refs = gui_data.refs.statistics

  local is_statistics_dirty = global.players[player_index].statistics.is_dirty

  refs.frame.dirty_info.visible = is_statistics_dirty

  for category_name, stat_category in pairs(get_statistics_categories(player_index)) do
    if not is_statistics_dirty then
      refs.frame[category_name].visible = true
    end
    for name, data in pairs(stat_category) do
      refs[category_name.."/"..name].caption = {"rb-gui.statistics-"..name, get_stat_value_string(data)}
    end
  end

  refs.scroll_pane.scroll_to_top()

end

return statistics_page