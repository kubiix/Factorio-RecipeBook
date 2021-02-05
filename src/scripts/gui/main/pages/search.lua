local constants = require("constants")
local formatter = require("scripts.formatter")

local search_page = {}

function search_page.build()
  return {
    {type = "frame", style = "subheader_frame", children = {
      {type = "label", style = "subheader_caption_label", caption = {"rb-gui.search-by"}},
      {type = "empty-widget", style = "flib_horizontal_pusher"},
      {
        type = "drop-down",
        items = constants.search_categories_localised,
        selected_index = 3,
        ref = {"search", "category_drop_down"},
        actions = {
          on_selection_state_changed = {gui = "main", page = "search", action = "change_category"}
        }
      }
    }},
    {type = "flow", style = "rb_search_content_flow", direction = "vertical", children = {
      {
        type = "textfield",
        style = "rb_search_textfield",
        clear_and_focus_on_right_click = true,
        ref = {"search", "textfield"},
        actions = {
          on_confirmed = {gui = "main", page = "search", action = "next_category"},
          -- update_results is a dummy action - the results will be updated regardless
          on_text_changed = {gui = "main", page = "search", action = "update_results"}
        }
      },
      {type = "frame", style = "rb_search_results_frame", direction = "vertical", children = {
        {
          type = "frame",
          style = "rb_search_results_subheader_frame",
          visible = false,
          ref = {"search", "limit_frame"},
          children = {
            {
              type = "label",
              style = "info_label",
              caption = {"", "[img=info] ", {"rb-gui.results-limited", constants.search_results_limit}}
            }
          }
        },
        {type = "scroll-pane", style = "rb_search_results_scroll_pane", ref = {"search", "results_scroll_pane"}}
      }}
    }}
  }
end

function search_page.init()
  return {
    category = "recipe"
  }
end

function search_page.handle_action(msg, e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.guis.main
  local state = gui_data.state
  local refs = gui_data.refs

  -- change category
  if msg.action == "change_category" then
    state.search.category = constants.search_categories[e.element.selected_index]
  elseif msg.action == "next_category" then
    local new_index = refs.search.category_drop_down.selected_index + 1
    if new_index > #constants.search_categories then
      new_index = 1
    end
    state.search.category = constants.search_categories[new_index]
    refs.search.category_drop_down.selected_index = new_index
  end

  -- update search results
  local query = string.lower(refs.search.textfield.text)

  local category = state.search.category
  local translations = player_table.translations[category]
  local scroll = refs.search.results_scroll_pane
  local rb_data = global.recipe_book[category]

  -- hide limit frame, show it again later if there's more than 50 results
  local limit_frame = refs.search.limit_frame
  limit_frame.visible = false

  -- don't show anything if there are zero or one letters in the query
  if string.len(query) < 2 then
    scroll.clear()
    return
  end

  -- fuzzy search
  if player_table.settings.use_fuzzy_search then
    query = string.gsub(query, ".", "%1.*")
  end

  -- input sanitization
  for pattern, replacement in pairs(constants.input_sanitizers) do
    query = string.gsub(query, pattern, replacement)
  end

  state.search.query = query

  -- settings and player data
  local player_data = {
    force_index = player.force.index,
    player_index = player.index,
    settings = player_table.settings,
    translations = player_table.translations
  }

  -- match queries and add or modify children
  local match_internal = player_table.settings.use_internal_names
  local children = scroll.children
  local add = scroll.add
  local i = 0
  for internal, translation in pairs(translations) do
    if string.find(string.lower(match_internal and internal or translation), query) then
      local obj_data = rb_data[internal]

      local temperatures = {}
      temperatures["dummy"] = { order = -0X1.FFFFFFFFFFFFFP+1023 }
      
      if obj_data.temperatures_count and player_data.settings.display_fluid_with_temperatures_in_search_results then
        if obj_data.temperatures_count == 1 then
          temperatures = {}
        end
        if (not player_data.settings.hide_fluid_with_range_temperatures_in_search_result) then
          for temperature_key, temperature in pairs(obj_data.temperatures) do
              temperatures[temperature_key] = { temperature_string = temperature.temperature_string, order = temperature.order }

              table.sort(temperatures, function(w1, w2) return w1.temperature_min < w2.temperature_min and w1.temperature_max < w2.temperature_max end)
          end
        else
          for temperature_key, temperature in pairs(obj_data.temperatures) do
            if string.match(temperature_key, '^(%d+)$') then
              temperatures[temperature_key] = { temperature_string = temperature.temperature_string, order = temperature.order }

              table.sort(temperatures, function(w1, w2) return w1.temperature_min < w2.temperature_min and w1.temperature_max < w2.temperature_max end)
            end
          end
        end
      end

      for temperature_key, temperature in pairs(temperatures) do
        if temperature_key == "dummy" then
          temperature_key = nil
        end

        local should_add, style, caption, tooltip = formatter(obj_data, player_data, { fluid_temperature_string = temperature.temperature_string, fluid_temperature_key = temperature_key, fluid_temperature_force = true })
        local context_data = {
          item_class = obj_data.sprite_class,
          item_name = obj_data.prototype_name,
          fluid_temperature_string = temperature.temperature_string,
          fluid_temperature_key = temperature_key,
          fluid_temperature_force = true
        }

        if should_add then
          i = i + 1
          -- create or modify element
          local child = children[i]
          if child then
            child.style = style
            child.caption = caption
            child.tooltip = tooltip
            child.tags = {
              [script.mod_name] = {
                flib = {
                  on_click = {gui = "main", action = "handle_list_box_item_click"}
                },
                context_data = context_data
              }
            }
          else
            add{
              type = "button",
              style = style,
              caption = caption,
              tooltip = tooltip,
              mouse_button_filter = {"left"},
              tags = {
                [script.mod_name] = {
                  flib = {
                    on_click = {gui = "main", action = "handle_list_box_item_click"}
                  },
                  context_data = context_data
                }
              }
            }
          end
          if i == constants.search_results_limit then
            limit_frame.visible = true
            break
          end
        end
      end




    end
  end

  -- remove extraneous children, if any
  if i < constants.search_results_limit then
    for j = i + 1, #scroll.children do
      children[j].destroy()
    end
  end
end

return search_page
