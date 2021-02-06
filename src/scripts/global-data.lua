local global_data = {}

local math = require("__flib__.math")
local table = require("__flib__.table")

local constants = require("constants")

local function unique_array(initial_value)
  local hash = {}
  if initial_value then
    for i = 1, #initial_value do
      hash[initial_value[i]] = true
    end
  end
  return setmetatable(initial_value or {}, {
    __newindex = function(tbl, key, value)
      if not hash[value] then
        hash[value] = true
        rawset(tbl, key, value)
      end
    end
  })
end

local function convert_and_sort(tbl)
  for key in pairs(tbl) do
    tbl[#tbl+1] = key
  end
  table.sort(tbl)
  return tbl
end

function global_data.init()
  global.flags = {}
  global.players = {}

  global_data.build_recipe_book()
  global_data.check_forces()
end

-- build amount string, to display probability, [min/max] amount - includes the "x"
local function build_amount_string(material)
  -- amount
  local amount = material.amount
  local amount_string = (
    amount
    and math.round_to(amount, 2).."x"
    or material.amount_min.." - "..material.amount_max.."x"
  )

  -- probability
  local probability = material.probability
  if probability and probability < 1 then
    amount_string = (probability * 100).."% "..amount_string
  end

  -- second return is the "average" amount
  return amount_string, amount == nil and ((material.amount_min + material.amount_max) / 2) or nil
end

local function build_temperature_strings(temperature_min, temperature_max)
  if temperature_min == temperature_max then
    return math.round_to(temperature_min, 2), " ("..math.round_to(temperature_min, 2).."°C"..")"
  end

  local min = -0X1.FFFFFFFFFFFFFP+1023
  local max = 0X1.FFFFFFFFFFFFFP+1023

  if temperature_min > min and temperature_max < max then 
    return math.round_to(temperature_min, 2).."-"..math.round_to(temperature_max, 2), " ("..math.round_to(temperature_min, 2).."-"..math.round_to(temperature_max, 2).."°C"..")"
  end

  if temperature_max < max then
    return  "≤"..math.round_to(temperature_max, 2), " (≤"..math.round_to(temperature_max, 2).."°C"..")"
  end

  if temperature_min > min then
    return  "≥"..math.round_to(temperature_min, 2)," (≥"..math.round_to(temperature_min, 2).."°C"..")"
  end
end

local function get_temperatures(material, obj_data)
  local default = obj_data.default_temperature
  local absolute_min = -0X1.FFFFFFFFFFFFFP+1023
  local absolute_max = 0X1.FFFFFFFFFFFFFP+1023
  
  local temperature_min
  local temperature_max

  if material.temperature then
    temperature_min = material.temperature
    temperature_max = material.temperature
  elseif material.minimum_temperature or material.maximum_temperature then
    temperature_min = material.minimum_temperature
    temperature_max = material.maximum_temperature

    if material.minimum_temperature <= absolute_min then
      temperature_min = absolute_min
    end

    if material.maximum_temperature >= absolute_max then
      temperature_max = absolute_max
    end

  else
    temperature_min = default
    temperature_max = default
  end

  local temperature_key, temperature_string = build_temperature_strings(temperature_min, temperature_max)

  return temperature_min, temperature_max, temperature_string, temperature_key
end

function global_data.build_recipe_book()
  local recipe_book = {
    crafter = {},
    lab = {},
    material = {},
    offshore_pump = {},
    recipe = {},
    resource = {},
    rocket_launch_product = {},
    technology = {}
  }
  local translation_data = {
    -- internal classes
    {dictionary = "gui", internal = "crafter", localised = {"rb-gui.crafter"}},
    {dictionary = "gui", internal = "fluid", localised = {"rb-gui.fluid"}},
    {dictionary = "gui", internal = "item", localised = {"rb-gui.item"}},
    {dictionary = "gui", internal = "lab", localised = {"rb-gui.lab"}},
    {dictionary = "gui", internal = "material", localised = {"rb-gui.material"}},
    {dictionary = "gui", internal = "offshore_pump", localised = {"rb-gui.offshore-pump"}},
    {dictionary = "gui", internal = "recipe", localised = {"rb-gui.recipe"}},
    {dictionary = "gui", internal = "resource", localised = {"rb-gui.resource"}},
    {dictionary = "gui", internal = "technology", localised = {"rb-gui.technology"}},
    -- captions
    {dictionary = "gui", internal = "hidden_abbrev", localised = {"rb-gui.hidden-abbrev"}},
    {dictionary = "gui", internal = "home_page", localised = {"rb-gui.home-page"}},
    -- tooltips
    {dictionary = "gui", internal = "blueprint_not_available", localised = {"rb-gui.blueprint-not-available"}},
    {dictionary = "gui", internal = "category", localised = {"rb-gui.category"}},
    {
      dictionary = "gui",
      internal = "control_click_to_view_fixed_recipe",
      localised = {"rb-gui.control-click-to-view-fixed-recipe"}
    },
    {dictionary = "gui", internal = "click_to_view", localised = {"rb-gui.click-to-view"}},
    {
      dictionary = "gui",
      internal = "click_to_view_required_fluid",
      localised = {"rb-gui.click-to-view-required-fluid"}
    },
    {dictionary = "gui", internal = "click_to_view_technology", localised = {"rb-gui.click-to-view-technology"}},
    {dictionary = "gui", internal = "crafting_categories", localised = {"rb-gui.crafting-categories"}},
    {dictionary = "gui", internal = "crafting_speed", localised = {"rb-gui.crafting-speed"}},
    {dictionary = "gui", internal = "crafting_time", localised = {"rb-gui.crafting-time"}},
    {dictionary = "gui", internal = "fixed_recipe", localised = {"rb-gui.fixed-recipe"}},
    {dictionary = "gui", internal = "fuel_categories", localised = {"rb-gui.fuel-categories"}},
    {dictionary = "gui", internal = "fuel_category", localised = {"rb-gui.fuel-category"}},
    {dictionary = "gui", internal = "fuel_value", localised = {"rb-gui.fuel-value"}},
    {dictionary = "gui", internal = "hidden", localised = {"rb-gui.hidden"}},
    {dictionary = "gui", internal = "ingredients_tooltip", localised = {"rb-gui.ingredients-tooltip"}},
    {dictionary = "gui", internal = "per_second", localised = {"rb-gui.per-second"}},
    {dictionary = "gui", internal = "products_tooltip", localised = {"rb-gui.products-tooltip"}},
    {dictionary = "gui", internal = "pumping_speed", localised = {"rb-gui.pumping-speed"}},
    {dictionary = "gui", internal = "required_fluid", localised = {"rb-gui.required-fluid"}},
    {dictionary = "gui", internal = "researching_speed", localised = {"rb-gui.researching-speed"}},
    {dictionary = "gui", internal = "rocket_parts_required", localised = {"rb-gui.rocket-parts-required"}},
    {dictionary = "gui", internal = "seconds_standalone", localised = {"rb-gui.seconds-standalone"}},
    {
      dictionary = "gui",
      internal = "shift_click_to_get_blueprint",
      localised = {"rb-gui.shift-click-to-get-blueprint"}
    },
    {dictionary = "gui", internal = "shift_click_to_view", localised = {"rb-gui.shift-click-to-view"}},
    {dictionary = "gui", internal = "stack_size", localised = {"rb-gui.stack-size"}},
    {dictionary = "gui", internal = "unresearched", localised = {"rb-gui.unresearched"}},
    {dictionary = "gui", internal = "free_fluid", localised = {"rb-gui.free-fluid"}}
  }

  -- iterate characters (as crafters)
  local character_prototypes = game.get_filtered_entity_prototypes{
    {filter = "type", type = "character"}
  }
  for name, prototype in pairs(character_prototypes) do
    -- add to recipe book
    recipe_book.crafter[name] = {
      available_to_all_forces = true,
      blueprintable = false,
      categories = convert_and_sort(prototype.crafting_categories),
      compatible_fuels = {},
      compatible_recipes = {},
      crafting_speed = 1,
      hidden = false,
      internal_class = "crafter",
      prototype_name = name,
      sprite_class = "entity"
    }
    -- add to translations table
    translation_data[#translation_data+1] = {
      dictionary = "crafter",
      internal = name,
      localised = prototype.localised_name
    }
    translation_data[#translation_data+1] = {
      dictionary = "crafter_description",
      internal = name,
      localised = prototype.localised_description
    }
  end

  -- iterate crafters
  local crafter_prototypes = game.get_filtered_entity_prototypes{
    {filter = "type", type = "assembling-machine"},
    {filter = "type", type = "furnace"},
    {filter = "type", type = "rocket-silo"}
  }
  local crafter_fuel_categories = {}
  local fixed_recipes = {}
  local rocket_silo_categories = {}
  for name, prototype in pairs(crafter_prototypes) do
    -- add fixed recipe to list
    if prototype.fixed_recipe then
      fixed_recipes[prototype.fixed_recipe] = true
    end
    -- add categories to rocket silo list
    if prototype.rocket_parts_required then
      for category in pairs(prototype.crafting_categories) do
        rocket_silo_categories[category] = true
      end
    end
    -- add to recipe book
    local is_hidden = prototype.has_flag("hidden")
    -- read burner prototype
    local fuel_categories
    local burner_prototype = prototype.burner_prototype
    if burner_prototype then
      crafter_fuel_categories[name] = burner_prototype.fuel_categories
      fuel_categories = {}
      for category in pairs(burner_prototype.fuel_categories) do
        fuel_categories[#fuel_categories+1] = category
      end
    end
    recipe_book.crafter[name] = {
      available_to_forces = {},
      blueprintable = not is_hidden and not prototype.has_flag("not-blueprintable"),
      categories = convert_and_sort(prototype.crafting_categories),
      compatible_fuels = {},
      compatible_recipes = {},
      crafting_speed = prototype.crafting_speed,
      fixed_recipe = prototype.fixed_recipe,
      fuel_categories = fuel_categories,
      hidden = is_hidden,
      internal_class = "crafter",
      prototype_name = name,
      rocket_parts_required = prototype.rocket_parts_required,
      sprite_class = "entity"
    }
    -- add to translations table
    translation_data[#translation_data+1] = {
      dictionary = "crafter",
      internal = name,
      localised = prototype.localised_name
    }
    translation_data[#translation_data+1] = {
      dictionary = "crafter_description",
      internal = name,
      localised = prototype.localised_description
    }
  end

  -- iterate materials
  local fluid_prototypes = game.fluid_prototypes
  local item_prototypes = game.item_prototypes
  local rocket_launch_payloads = {}
  for class, t in pairs{fluid = fluid_prototypes, item = item_prototypes} do
    for name, prototype in pairs(t) do
      local hidden
      if class == "fluid" then
        hidden = prototype.hidden
      else
        hidden = prototype.has_flag("hidden")
      end
      local launch_products = class == "item" and prototype.rocket_launch_products or {}
      local default_categories = (#launch_products > 0 and table.shallow_copy(rocket_silo_categories)) or {}
      -- process rocket launch products
      if launch_products then
        for i = 1, #launch_products do
          local product = launch_products[i]
          -- add amount strings
          local amount_string = build_amount_string(product)
          launch_products[i] = {
            type = product.type,
            name = product.name,
            amount_string = amount_string
          }
          -- add to rocket launch payloads table
          local product_key = product.type.."."..product.name
          local product_payloads = rocket_launch_payloads[product_key]
          if product_payloads then
            product_payloads[#product_payloads+1] = {type = class, name = name}
          else
            rocket_launch_payloads[product_key] = {{type = class, name = name}}
          end
        end
      end
      -- read fuel category
      local fuel_category = class == "item" and prototype.fuel_category or nil
      local burnable_in = {}
      if fuel_category then
        for crafter_name, categories in pairs(crafter_fuel_categories) do
          if categories[fuel_category] then
            burnable_in[#burnable_in+1] = crafter_name
            local crafter_data = recipe_book.crafter[crafter_name]
            crafter_data.compatible_fuels[#crafter_data.compatible_fuels+1] = {type = "item", name = name}
          end
        end
      end
      -- add to recipe book
      recipe_book.material[class.."."..name] = {
        available_to_forces = {},
        burnable_in = burnable_in,
        fuel_category = fuel_category,
        fuel_value = prototype.fuel_value > 0 and prototype.fuel_value or nil,
        hidden = hidden,
        ingredient_in = {},
        internal_class = "material",
        mined_from = {},
        product_of = {},
        prototype_name = name,
        pumped_by = {},
        recipe_categories = default_categories,
        rocket_launch_payloads = {},
        rocket_launch_products = launch_products,
        sprite_class = class,
        stack_size = class == "item" and prototype.stack_size or nil,
        unlocked_by = unique_array(),
        usable_in = {},
        temperatures = {},
        temperatures_count = 0
      }
      -- add to translations table
      translation_data[#translation_data+1] = {
        dictionary = "material",
        internal = class.."."..name,
        localised = prototype.localised_name
      }
      translation_data[#translation_data+1] = {
        dictionary = "material_description",
        internal = class.."."..name,
        localised = prototype.localised_description
      }
    end
  end

  -- iterate labs
  -- this has to be done after materials
  local lab_prototypes = game.get_filtered_entity_prototypes{
    {filter = "type", type = "lab"}
  }
  for name, prototype in pairs(lab_prototypes) do
    -- add to materials
    for _, item_name in ipairs(prototype.lab_inputs) do
      local item_data = recipe_book.material["item."..item_name]
      if item_data then
        item_data.usable_in[#item_data.usable_in+1] = name
      end
    end
    -- add to recipe book
    recipe_book.lab[name] = {
      available_to_forces = {},
      hidden = prototype.has_flag("hidden"),
      internal_class = "lab",
      inputs = prototype.lab_inputs,
      prototype_name = name,
      researching_speed = prototype.researching_speed,
      sprite_class = "entity"
    }
    -- add to translations table
    translation_data[#translation_data+1] = {dictionary = "lab", internal = name, localised = prototype.localised_name}
    translation_data[#translation_data+1] = {
      dictionary = "lab_description",
      internal = name,
      localised = prototype.localised_description
    }
  end

  -- iterate offshore pumps
  local offshore_pump_prototypes = game.get_filtered_entity_prototypes{
    {filter = "type", type = "offshore-pump"}
  }
  for name, prototype in pairs(offshore_pump_prototypes) do
    -- add to material
    local fluid = prototype.fluid
    local fluid_data = recipe_book.material["fluid."..fluid.name]
    if fluid_data then
      fluid_data.pumped_by[#fluid_data.pumped_by+1] = name
    end
    -- add to recipe book
    recipe_book.offshore_pump[name] = {
      available_to_all_forces = true,
      fluid = prototype.fluid.name,
      hidden = prototype.has_flag("hidden"),
      internal_class = "offshore_pump",
      prototype_name = name,
      pumping_speed = prototype.pumping_speed,
      sprite_class = "entity"
    }
    -- add to translations table
    translation_data[#translation_data+1] = {
      dictionary = "offshore_pump",
      internal = name,
      localised = prototype.localised_name
    }
    translation_data[#translation_data+1] = {
      dictionary = "offshore_pump_description",
      internal = name,
      localised = prototype.localised_description
    }
  end

  -- iterate recipes
  local recipe_prototypes = game.recipe_prototypes
  for name, prototype in pairs(recipe_prototypes) do
    local data = {
      available_to_forces = {},
      category = prototype.category,
      energy = prototype.energy,
      hidden = prototype.hidden,
      internal_class = "recipe",
      made_in = {},
      prototype_name = name,
      sprite_class = "recipe",
      unlocked_by = {},
      used_as_fixed_recipe = fixed_recipes[name]
    }

    -- ingredients / products
    for _, mode in ipairs{"ingredients", "products"} do
      local materials = prototype[mode]
      local output = {}
      for i = 1, #materials do
        local material = materials[i]
        local amount_string, avg_amount_string = build_amount_string(material)

        local temperature_min, temperature_max
        local temperature_string, temperature_key

        if material.type == "fluid" then
          local obj_data = game.fluid_prototypes[material.name]
          local fluid_data = recipe_book.material["fluid."..material.name]
          
          temperature_min, temperature_max, temperature_string, temperature_key = get_temperatures(material, obj_data)

          -- add fluid temperature to all possible temperatures of this fluid
          -- skip temperatures from PyanodonIndustry dynamic recipes for voiding Fluids in Py-Sinkhole / Py-GasVent
          if not fluid_data.temperatures[temperature_key] and prototype.category ~= "py-venting" and prototype.category ~= "py-runoff" then
            fluid_data.temperatures_count =fluid_data.temperatures_count + 1
            fluid_data.temperatures[temperature_key] = {
              temperature_string = temperature_string,
              temperature_min = temperature_min,
              temperature_max = temperature_max,
    }
  end
        end

        -- save only the essentials
        output[i] = {
          type = material.type,
          name = material.name,
          amount_string = amount_string,
          avg_amount_string = avg_amount_string,
          fluid_temperature_string = temperature_string,
          fluid_temperature_key = temperature_key,
          temperature_min = temperature_min,
          temperature_max = temperature_max
        }
      end
      -- add to data
      data[mode] = output
    end
    -- made in
    local category = prototype.category
    for crafter_name, crafter_data in pairs(recipe_book.crafter) do
      if crafter_data.categories[category] then
        local rocket_parts_str = crafter_data.rocket_parts_required and crafter_data.rocket_parts_required.."x  " or ""
        data.made_in[#data.made_in+1] = {
          name = crafter_name,
          amount_string = rocket_parts_str.."("..math.round_to(prototype.energy / crafter_data.crafting_speed, 2).."s)"
        }
        crafter_data.compatible_recipes[#crafter_data.compatible_recipes+1] = name
      end
    end

    -- material: ingredient in
    local ingredients = prototype.ingredients
    for i = 1, #ingredients do
      local ingredient = ingredients[i]
      local ingredient_data = recipe_book.material[ingredient.type.."."..ingredient.name]
      if ingredient_data then
        local temperature_key_in
        if ingredient.type == "fluid" then
          local obj_data = game.fluid_prototypes[ingredient_data.prototype_name]
          _, _, _, _, temperature_key_in = get_temperatures(ingredient, obj_data)
        end

        ingredient_data.recipe_categories[data.category] = true
        ingredient_data.ingredient_in[#ingredient_data.ingredient_in+1] = { name = name, fluid_temperature_key = temperature_key_in}
      end
    end
    -- material: product of
    local products = prototype.products
    for i = 1, #products do
      local product = products[i]
      local product_data = recipe_book.material[product.type.."."..product.name]
      if product_data then
        local temperature_key_pr
        if product.type == "fluid" then
          local obj_data = game.fluid_prototypes[product_data.prototype_name]
          _, _, _, _, temperature_key_pr = get_temperatures(product, obj_data)
        end

        product_data.recipe_categories[data.category] = true
        product_data.product_of[#product_data.product_of+1] = { name = name, fluid_temperature_key = temperature_key_pr}
      end
    end
    -- insert into recipe book
    recipe_book.recipe[name] = data
    -- insert into translations table
    translation_data[#translation_data+1] = {
      dictionary = "recipe",
      internal = name,
      localised = prototype.localised_name
    }
    translation_data[#translation_data+1] = {
      dictionary = "recipe_description",
      internal = name,
      localised = prototype.localised_description
    }
  end

  -- iterate resources
  local resource_prototypes = game.get_filtered_entity_prototypes{{filter = "type", type = "resource"}}
  for name, prototype in pairs(resource_prototypes) do
    local products = prototype.mineable_properties.products
    if products then
      for _, product in ipairs(products) do
        local product_data = recipe_book.material[product.type.."."..product.name]
        if product_data then
          product_data.mined_from[#product_data.mined_from+1] = name
        end
      end
    end
    local required_fluid
    local mineable_properties = prototype.mineable_properties
    if mineable_properties.required_fluid then
      required_fluid = {
        name = mineable_properties.required_fluid,
        amount_string = build_amount_string{amount = mineable_properties.fluid_amount}
      }
    end
    -- insert into recipe book
    recipe_book.resource[name] = {
      available_to_all_forces = true,
      internal_class = "resource",
      prototype_name = name,
      required_fluid = required_fluid,
      sprite_class = "entity"
    }
    -- insert into translations table
    translation_data[#translation_data+1] = {
      dictionary = "resource",
      internal = name,
      localised = prototype.localised_name
    }
    translation_data[#translation_data+1] = {
      dictionary = "resource_description",
      internal = name,
      localised = prototype.localised_description
    }
  end

  -- iterate technologies
  for name, prototype in pairs(game.technology_prototypes) do
    if prototype.enabled then
      for _, modifier in ipairs(prototype.effects) do
        if modifier.type == "unlock-recipe" then
          local recipe_data = recipe_book.recipe[modifier.recipe]
          if recipe_data then
            recipe_data.unlocked_by[#recipe_data.unlocked_by+1] = name

            for _, product in pairs(recipe_data.products) do
              local product_name = product.name
              local product_type = product.type
              -- product
              local product_data = recipe_book.material[product_type.."."..product_name]
              local temperature_key_re
              if product.type == "fluid" then
                temperature_key_re = product.fluid_temperature_key
              end

              if product_data then
                -- check if we've already been added here
                local add = true 
                local add2 = true
                for _, technology in ipairs(product_data.unlocked_by) do
                  if technology and technology.name == name then
                    add = false
                    for _, fluid_temperature_key in ipairs(technology.fluid_temperature_keys) do
                      if fluid_temperature_key == temperature_key_re then
                        add2 = false
                        break
                      end
                    end
                    if add2 then
                      technology.fluid_temperature_keys[#technology.fluid_temperature_keys+1] = temperature_key_re
                    end
                    break
                  end
                end
                if add then
                  product_data.unlocked_by[#product_data.unlocked_by+1] = { name = name, fluid_temperature_keys = { temperature_key_re } }
                end
              end
            end
          end
        end
      end
      -- insert into recipe book
      recipe_book.technology[name] = {
        hidden = prototype.hidden,
        internal_class = "technology",
        prototype_name = name,
        researched_forces = {},
        sprite_class = "technology"
      }
      -- insert into translations table
      translation_data[#translation_data+1] = {
        dictionary = "technology",
        internal = prototype.name,
        localised = prototype.localised_name
      }
    translation_data[#translation_data+1] = {
      dictionary = "technology_description",
      internal = name,
      localised = prototype.localised_description
    }
    end
  end

  -- add rocket launch payloads to their material tables
  for product, payloads in pairs(rocket_launch_payloads) do
    local product_data = recipe_book.material[product]
    product_data.rocket_launch_payloads = table.array_copy(payloads)
    for i = 1, #payloads do
      local payload = payloads[i]
      local payload_data = recipe_book.material[payload.type.."."..payload.name]
      local payload_unlocked_by = payload_data.unlocked_by
      for j = 1, #payload_unlocked_by do
        product_data.unlocked_by[#product_data.unlocked_by+1] = payload_unlocked_by[j]
      end
    end
  end

  -- remove all materials that aren't used
  do
    local materials = recipe_book.material
    local translations = translation_data
    for i = #translations, 1, -1 do
      local t = translations[i]
      if t.dictionary == "material" then
        local data = materials[t.internal]
        if
          #data.burnable_in == 0
          and #data.ingredient_in == 0
          and #data.mined_from == 0
          and #data.product_of == 0
          and #data.pumped_by == 0
          and #data.rocket_launch_products == 0
          and #data.rocket_launch_payloads == 0
          and #data.usable_in == 0
        then
          materials[t.internal] = nil
          table.remove(translations, i)
        elseif #data.unlocked_by == 0 then
          -- set unlocked by default
          data.available_to_forces = nil
          data.available_to_all_forces = true
        end
      end
    end
  end

  -- apply to global
  global.recipe_book = recipe_book
  global.translation_data = translation_data
end

local function unlock_launch_products(force_index, launch_products, recipe_book)
  for _, launch_product in ipairs(launch_products) do
    local launch_product_data = recipe_book.material[launch_product.type.."."..launch_product.name]
    if launch_product_data and launch_product_data.available_to_forces then
      launch_product_data.available_to_forces[force_index] = true
    end
    unlock_launch_products(force_index, launch_product_data.rocket_launch_products, recipe_book)
  end
end

local function set_recipe_available(force_index, recipe_data, recipe_book, item_prototypes)
  -- check if the category should be ignored for recipe availability
  local disabled = constants.disabled_recipe_categories[recipe_data.category]
  if disabled and disabled == 0 then return end
  recipe_data.available_to_forces[force_index] = true
  for _, product in ipairs(recipe_data.products) do
    -- product
    local product_data = recipe_book.material[product.type.."."..product.name]
    if product_data and product_data.available_to_forces then
      if product.type == "fluid" then
        if not product_data.available_to_forces[force_index] then
          product_data.available_to_forces[force_index] = {}
          product_data.available_to_forces[force_index][tostring(product.fluid_temperature_key)] = true
        elseif not product_data.available_to_forces[force_index][tostring(product.fluid_temperature_key)] then
          product_data.available_to_forces[force_index][tostring(product.fluid_temperature_key)] = true
        end
      else
        product_data.available_to_forces[force_index] = true
      end
    end
    -- crafter / lab
    if product.type == "item" then
      local place_result = item_prototypes[product.name].place_result
      if place_result then
        local entity_data = recipe_book.crafter[place_result.name] or recipe_book.lab[place_result.name]
        if entity_data and entity_data.available_to_forces then
          entity_data.available_to_forces[force_index] = true
        end
      end
    end
    -- rocket launch products
    unlock_launch_products(force_index, product_data.rocket_launch_products, recipe_book)
  end
end

function global_data.update_available_objects(technology)
  local force_index = technology.force.index
  local item_prototypes = game.item_prototypes
  local recipe_book = global.recipe_book
  -- technology
  local technology_data = recipe_book.technology[technology.name]
  if technology_data then
    technology_data.researched_forces[force_index] = true
  end
  -- recipes
  for _, effect in ipairs(technology.effects) do
    if effect.type == "unlock-recipe" then
      local recipe_data = recipe_book.recipe[effect.recipe]
      if recipe_data and not recipe_data.available_to_forces[force_index] then
        set_recipe_available(force_index, recipe_data, recipe_book, item_prototypes)
      end
    end
  end
end

function global_data.check_force_recipes(force)
  local item_prototypes = game.item_prototypes
  local recipe_book = global.recipe_book
  local force_index = force.index
  for name, recipe in pairs(force.recipes) do
    if recipe.enabled then
      local recipe_data = recipe_book.recipe[name]
      if recipe_data then
        set_recipe_available(force_index, recipe_data, recipe_book, item_prototypes)
      end
    end
  end
end

function global_data.check_force_technologies(force)
  local force_index = force.index
  local technologies = global.recipe_book.technology
  for name, technology in pairs(force.technologies) do
    if technology.enabled and technology.researched then
      local technology_data = technologies[name]
      if technology_data then
        technology_data.researched_forces[force_index] = true
      end
    end
  end
end

function global_data.check_forces()
  for _, force in pairs(game.forces) do
    global_data.check_force_recipes(force)
    global_data.check_force_technologies(force)
  end
end

return global_data
