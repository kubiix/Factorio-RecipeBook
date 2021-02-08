local info_list_box = require("scripts.gui.main.info-list-box")

local recipe_page = {}

function recipe_page.build(prefix)
  prefix = prefix or ""
  local elems =  {
    info_list_box.build({"rb-gui.ingredients"}, 1, {prefix.."recipe", "ingredients"}),
    info_list_box.build({"rb-gui.products"}, 1, {prefix.."recipe", "products"}),
    info_list_box.build({"rb-gui.made-in"}, 1, {prefix.."recipe", "made_in"}),
    info_list_box.build({"rb-gui.unlocked-by"}, 1, {prefix.."recipe", "unlocked_by"})
  }

  -- add time item to ingredients
  elems[1].children[2].children[1].children = {
    {
      type = "button",
      name = "rb_list_box_item__1",
      style = "rb_list_box_item",
      tooltip = {"rb-gui.seconds-tooltip"},
      enabled = false,
      ref = {prefix.."recipe", "ingredients", "time_item"}
    }
  }

  return elems
end

function recipe_page.update(int_name, gui_data, player_data, _, _, sub_recipe)
  local recipe = gui_data.refs.recipe

  if sub_recipe then
    recipe = gui_data.refs.sub_recipe
  end

  local obj_data = global.recipe_book.recipe[int_name]

  -- set time item
  local time_item_prefix = player_data.settings.show_glyphs and "[font=RecipeBook]Z[/font]   " or ""
  local time_item = recipe.ingredients.time_item
  time_item.caption = {
    "",
    time_item_prefix.."[img=quantity-time]   [font=default-bold]",
    {"rb-gui.seconds", obj_data.energy},
    "[/font]"
  }

  info_list_box.update(obj_data.ingredients, "material", recipe.ingredients, player_data, {always_show = true, starting_index = 1}  )
  info_list_box.update(obj_data.products, "material", recipe.products, player_data, {always_show = true})
  info_list_box.update(obj_data.made_in, "crafter", recipe.made_in, player_data, {blueprint_recipe = int_name})
  info_list_box.update(obj_data.unlocked_by, "technology", recipe.unlocked_by, player_data)
end

return recipe_page
