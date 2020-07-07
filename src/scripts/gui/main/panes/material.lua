local material_pane = {}

local gui = require("__flib__.gui")

-- gui.add_templates{

-- }

function material_pane.update(parent, gui_data, translations)
  -- parent.clear()
  -- gui.build(parent, {
  --   {type="flow", style_mods={horizontally_stretchable=true, vertically_stretchable=true, horizontal_align="center", vertical_align="center"}, children={
  --     {type="label", style="bold_label", caption="Material page"}
  --   }}
  -- })
end

function material_pane.build()
  return {
    gui.templates.info_list_box({"rb-gui.ingredient-in"}, 1, "material.ingredient_in"),
    gui.templates.info_list_box({"rb-gui.product-of"}, 1, "material.product_of"),
    gui.templates.info_list_box({"rb-gui.mined-from"}, 1, "material.mined_from"),
    gui.templates.info_list_box({"rb-gui.pumped-by"}, 1, "material.pumped_by"),
    gui.templates.info_list_box({"rb-gui.unlocked-by"}, 1, "material.unlocked_by")
  }
end

return material_pane