local base_gui = {}

local gui = require("__flib__.gui")

local search_pane = require("scripts.gui.panes.search")

local content_panes = {}

function base_gui.create(player, player_table)

end

function base_gui.destroy(player, player_table)
  gui.remove_player_filters(player.index)
  -- TODO
end

return base_gui