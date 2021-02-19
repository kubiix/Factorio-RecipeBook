local statistics_proc = {}

-- properties
local function get_properties(obj_data, force_index)
  local researched
  if obj_data.enabled_at_start then
    researched = true
  elseif obj_data.researched_forces then
    researched = obj_data.researched_forces[force_index] or false
  else
    researched = true
  end
  return obj_data.hidden, researched
end

local function get_should_show(obj_data, player_table)
  local player_settings = player_table.settings

  -- check hidden and researched status
  local is_hidden, is_researched = get_properties(obj_data, player_table.force_index)
  -- for recipes - check category to see if it should be shown
  local category = obj_data.category
  local categories = obj_data.recipe_categories
  if category then
    if player_settings.recipe_categories[category] then
      return true, is_hidden, is_researched
    end
  -- for materials - check if any of their categories are enabled
  elseif categories then
    local category_settings = player_settings.recipe_categories
    for _, category_name in ipairs(categories) do
      if category_settings[category_name] then
        return true, is_hidden, is_researched
      end
    end
  else
    return true, is_hidden, is_researched
  end
  return false, is_hidden, is_researched
end

local function add_stat(category, name, prefix, suffix, player_table, initial_value)
  player_table.statistics.categories[category][name] = { prefix = prefix, suffix = suffix, value = initial_value }
end

local function set_stat_value(category, name, player_table, value)
  local stat = player_table.statistics.categories[category][name]
  stat.value = value
end

local function increment_stat_value(category, name, player_table, increment)
  local stat = player_table.statistics.categories[category][name]
  stat.value = stat.value + increment
end

local function init_category(recipe_book, category, player_table, without_data)
  add_stat(category, "total", nil, nil, player_table, 0)

  if (category == "fluid") then
    add_stat(category, "total_without_temperature", nil, nil, player_table, 0)
  end

  add_stat(category, "hidden", nil, nil, player_table, 0)
  add_stat(category, "hidden_by_settings", nil, nil, player_table, 0)
  add_stat(category, "enabled_at_start", nil, nil, player_table, 0)
  add_stat(category, "researched", nil, nil, player_table, 0)

  if without_data then
    return
  end

  for _, obj_data in pairs(recipe_book[category]) do
    if obj_data.placeable_by or category ~= "crafter" then

      local should_show, is_hidden, is_researched = get_should_show(obj_data, player_table)

      if obj_data.category or (obj_data.recipe_categories and #obj_data.recipe_categories > 0) or category ~= "item" then

        if should_show then
          increment_stat_value(category, "total", player_table, 1)
        end

        if is_hidden then
          increment_stat_value(category, "hidden", player_table, 1)
        elseif not should_show then
          increment_stat_value(category, "hidden_by_settings", player_table, 1)
        elseif not obj_data.researched_forces then
          increment_stat_value(category, "enabled_at_start", player_table, 1)
        elseif is_researched then
          increment_stat_value(category, "researched", player_table, 1)
      end

    end


      -- if category == "fluid" and obj_data.temperatures then
      --   increment_stat_value(category, "total_without_temperature", nil, 1)

      --   for key, value in pairs(obj_data.temperatures) do


      --     increment_stat_value(category, "total", nil, 1)

      --     if not obj_data.researched_forces then
      --       increment_stat_value(category, "enabled_at_start", nil, 1)
      --     elseif obj_data.hidden then
      --       increment_stat_value(category, "hidden", nil, 1)
      --     elseif obj_data.researched_forces then
      --       for key, value in ipairs(obj_data.researched_forces) do
      --         if value then
      --           increment_stat_value(category, "researched", key, 1)
      --         end
      --       end
      --     end
      --   end

      -- else
      --   increment_stat_value(category, "total", nil, 1)

      --   if not obj_data.researched_forces then
      --     increment_stat_value(category, "enabled_at_start", nil, 1)
      --   elseif obj_data.hidden then
      --     increment_stat_value(category, "hidden", nil, 1)
      --   elseif obj_data.researched_forces then
      --     for key, value in ipairs(obj_data.researched_forces) do
      --       if value then
      --         increment_stat_value(category, "researched", key, 1)
      --       end
      --     end
      --   end
      -- end
    end
  end
end

statistics_proc.init = function (recipe_book, player_table)
  for _, category in ipairs{ "crafter", "fluid", "item", "recipe", "resource", "technology" } do
    init_category(recipe_book, category, player_table, true)
  end


end

statistics_proc.calculate = function (recipe_book, player_table)
  for _, category in ipairs{ "crafter", "fluid", "item", "recipe", "resource", "technology" } do
    init_category(recipe_book, category, player_table, false)
  end
  player_table.statistics.is_dirty = false

end

statistics_proc.set_dirty = function (player_table)
  player_table.statistics.is_dirty = true
end

return statistics_proc