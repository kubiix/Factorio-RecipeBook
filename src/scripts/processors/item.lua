local table = require("__flib__.table")

local util = require("scripts.util")

return function(recipe_book, strings, metadata)
  local rocket_launch_payloads = {}
  for name, prototype in pairs(game.item_prototypes) do
    -- rocket launch products
    local launch_products = {}
    for i, product in ipairs(prototype.rocket_launch_products or {}) do
      -- add to products table w/ amount string
      local amount_string, quick_ref_amount_string = util.build_amount_string(product)
      launch_products[i] = {
        class = product.type,
        name = product.name,
        amount_string = amount_string,
        quick_ref_amount_string = quick_ref_amount_string
      }
      -- add to payloads table
      local product_payloads = rocket_launch_payloads[product.name]
      if product_payloads then
        product_payloads[#product_payloads + 1] = {class = product.type, name = product.name}
      else
        rocket_launch_payloads[product.name] = {{class = product.type, name = product.name}}
      end
    end
    local default_categories = util.unique_string_array(
      #launch_products > 0 and table.shallow_copy(metadata.rocket_silo_categories) or {}
    )

    local place_result = prototype.place_result
    if place_result then
      place_result = place_result.name
      local result_data = recipe_book.crafter[place_result] or recipe_book.lab[place_result]
      if result_data then
        result_data.placeable_by[#result_data.placeable_by + 1] = {class = "item", name = name}
      else
        place_result = nil
      end
    end

    local fuel_value = prototype.fuel_value
    local has_fuel_value = prototype.fuel_value > 0
    local fuel_acceleration_multiplier = prototype.fuel_acceleration_multiplier
    local fuel_emissions_multiplier = prototype.fuel_emissions_multiplier
    local fuel_top_speed_multiplier = prototype.fuel_top_speed_multiplier

    recipe_book.item[name] = {
      class = "item",
      fuel_acceleration_multiplier = (
        has_fuel_value
        and fuel_acceleration_multiplier ~= 1
        and fuel_acceleration_multiplier
        or nil
      ),
      fuel_emissions_multiplier = (
        has_fuel_value
        and fuel_emissions_multiplier ~= 1
        and fuel_emissions_multiplier
        or nil
      ),
      fuel_top_speed_multiplier = (
        has_fuel_value
        and fuel_top_speed_multiplier ~= 1
        and fuel_top_speed_multiplier
        or nil
      ),
      fuel_value = has_fuel_value and fuel_value or nil,
      hidden = prototype.has_flag("hidden"),
      ingredient_in = {},
      mined_from = {},
      place_result = place_result,
      product_of = {},
      prototype_name = name,
      recipe_categories = default_categories,
      rocket_launch_payloads = {},
      rocket_launch_products = launch_products,
      stack_size = prototype.stack_size,
      unlocked_by = util.unique_obj_array(),
      usable_in = {}
    }
    util.add_string(strings, {dictionary = "item", internal = name, localised = prototype.localised_name})
    util.add_string(strings, {
      dictionary = "item_description",
      internal = name,
      localised = prototype.localised_description
    })
  end

  -- add rocket launch payloads to their material tables
  for product, payloads in pairs(rocket_launch_payloads) do
    local product_data = recipe_book.item[product]
    product_data.rocket_launch_payloads = table.array_copy(payloads)
    for i = 1, #payloads do
      local payload = payloads[i]
      local payload_data = recipe_book.item[payload.name]
      local payload_unlocked_by = payload_data.unlocked_by
      for j = 1, #payload_unlocked_by do
        product_data.unlocked_by[#product_data.unlocked_by + 1] = payload_unlocked_by[j]
      end
    end
  end
end
