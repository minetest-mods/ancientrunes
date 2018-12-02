--[[
=====================================================================
** Ancient Runes **
Copyright (c) 2018 Marius Spix <marius.spix@web.de>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
=====================================================================
--]]

-- Load support for intllib.
local MP = minetest.get_modpath(minetest.get_current_modname())
local S, NS = dofile(MP.."/intllib.lua")

local function display_powder(position, texture)
  local minpos, maxpos = vector.subtract(position, 6), vector.add(position, 6)

  minetest.add_particlespawner({
    amount = 64,
    time = 4,
    minpos = minpos,
    maxpos = maxpos,
    minvel = {x = -10, y = -10, z = -10},
    maxvel = {x = 10, y = 10, z = 10},
    minacc = vector.new(),
    maxacc = vector.new(),
    minexptime = 1,
    maxexptime = 4,
    minsize =  2,
    maxsize =  6,
    texture = texture,
  })
end

local function give_or_drop_item(item, user)
  local inventory = user:get_inventory( )

  if inventory:room_for_item("main", item) then
    inventory:add_item("main", item)
  else
    minetest.add_item(user:get_pos(), item)
  end
end

local function register_rune_recipe(output, r1, r2, r3)
  minetest.register_craft({
    output = "ancientrunes:rune_"..output,
    recipe = { r1, r2, r3 }})
end

local function attach_rune(itemstack, player, pointed_thing)
    if pointed_thing.type ~= "node" then
       return
    end

    if minetest.is_protected(pointed_thing.under, player:get_player_name()) then
       return
    end

    local node = minetest.get_node(pointed_thing.under)
    local node_name, is_default_block = node.name:gsub("default:(.*_block)","%1")

    if is_default_block == 0 then
       return
    end

    if     node_name == "stone_block"
		or node_name == "sandstone_block"
		or node_name == "desert_stone_block"
		or node_name == "desert_sandstone_block"
		or node_name == "silver_sandstone_block"
		or node_name == "obsidian_block"
    then
        local rune = itemstack:get_name():sub(19)
        minetest.set_node(pointed_thing.under, { name = "ancientrunes:"..node_name.."_"..rune })

		if not minetest.settings:get_bool("creative_mode") then
			itemstack:take_item()
            return itemstack
		end
    end
end

local function register_burins()
	local materials = {
	  { material = "wood",    resource = "group:wood",           name = S("Wood Burin"),    times = { [1] = 3.61, [2] = 2.28, [3] = 0.94 },  uses =  8 },
	  { material = "stone",   resource = "group:stone",          name = S("Stone Burin"),   times = { [1] = 2.69, [2] = 1.74, [3] = 0.79 },  uses = 11 },
	  { material = "steel",   resource = "default:steel_ingot",  name = S("Steel Burin"),   times = { [1] = 1.41, [2] = 0.97, [3] = 0.52 },  uses = 21 },
	  { material = "bronze",  resource = "default:bronze_ingot", name = S("Bronze Burin"),  times = { [1] = 1.14, [2] = 0.80, [3] = 0.46 },  uses = 26 },
	  { material = "mese",    resource = "default:mese_crystal", name = S("Mese Burin"),    times = { [1] = 0.43, [2] = 0.33, [3] = 0.24 },  uses = 70 },
	  { material = "diamond", resource = "default:diamond",      name = S("Diamond Burin"), times = { [1] = 0.37, [2] = 0.29, [3] = 0.21 },  uses = 82 }
	}

	local drops = {
	  ["default:stone"]              = { iron_powder =  9, mese_powder =  1 },
	  ["default:stone_with_coal"]    = { iron_powder =  9, mese_powder =  1 },
	  ["default:stone_with_iron"]    = { iron_powder = 80, mese_powder =  0 },
	  ["default:stone_with_copper"]  = { iron_powder = 17, mese_powder =  1 },
	  ["default:stone_with_tin"]     = { iron_powder = 17, mese_powder =  1 },
	  ["default:stone_with_gold"]    = { iron_powder = 58, mese_powder =  4 },
	  ["default:stone_with_mese"]    = { iron_powder =  0, mese_powder = 20 },
	  ["default:stone_with_diamond"] = { iron_powder = 28, mese_powder = 10 }
	}

	if minetest.get_modpath("moreores") then
	  table.insert( materials, { material = "silver",  resource = "moreores:silver_ingot",  name = S("Silver Burin"),  times = { [1] = 0.60, [2] = 0.45, [3] = 0.30 }, uses = 50 } )
	  table.insert( materials, { material = "mithril", resource = "moreores:mithril_ingot", name = S("Mithril Burin"), times = { [1] = 0.41, [2] = 0.32, [3] = 0.23 }, uses = 73 } )
	  drops["moreores:mineral_silver"]  = { iron_powder = 70, mese_powder =  2 }
	  drops["moreores:mineral_mithril"] = { iron_powder = 36, mese_powder =  6 }
	end

	minetest.register_on_punchnode(
	function(pos, node, puncher, pointed_thing)
	  local item = puncher:get_wielded_item()
	  if item and item:get_name():find("^ancientrunes:burin_.+$") then
		local drop = drops[node.name]

		if drop then
		  local rand_value = math.random(100)

		  if rand_value <= drop.mese_powder then
		    give_or_drop_item("ancientrunes:mese_powder", puncher)
		    display_powder(puncher:get_pos(), "ancientrunes_particle_mese_powder.png")
		  elseif rand_value <= drop.iron_powder then
		    give_or_drop_item("ancientrunes:iron_powder", puncher)
		    display_powder(puncher:get_pos(), "ancientrunes_particle_iron_powder.png")
		  end

		  item:add_wear(65535/item:get_tool_capabilities().groupcaps.cracky.uses)

		  if item:get_wear() == 0 then
		    minetest.sound_play("default_tool_breaks", {pos = pointed_thing})
		    puncher:set_wielded_item(nil)
		  else
		    puncher:set_wielded_item(item)
		  end
		end

		-- Place node back
		minetest.set_node(pos, node)
	  end
	end
	)

	for i = 1, #materials do
	  local m          = materials[i]
	  local burin_name = "ancientrunes:burin_"..m.material

	  minetest.register_tool(burin_name, {
		description = m.name,
		inventory_image = "ancientrunes_tool_burin_"..m.material..".png",
		tool_capabilities = {
		  groupcaps = {
		    cracky  = { times = m.times, uses = m.uses, maxlevel = 1 }
		  }
		}
	  })

	  minetest.register_craft({
		output = burin_name,
		recipe = {
		  {m.resource, "default:flint", m.resource},
		  {"", "group:stick", ""},
		  {"", "group:stick", ""}
		}
	  })
	end
end

local function register_runes()
	local runes = {"algiz","ansuz","berkanan","dagaz","ehwaz","fehu","gyfu","hagalaz","ihwa","isaz","jera","kaunan","laguz","mannaz","naudiz","othala","peorth","raido","sowilo","thurisaz","tiwaz","ur","wynn","yngvi"}

	for i = 1, #runes do
	  local r                = runes[i]
	  local rune_name        = "ancientrunes:rune_"..r
	  local rune_description = S(r:gsub("^%l", string.upper))
	  local rune_image       = "ancientrunes_overlay_"..r..".png"

	  minetest.register_craftitem(rune_name, {
		description     = S("@1 Rune", rune_description),
		inventory_image = rune_image,
		on_use          = attach_rune
	  })

	  local node_names = { stone_block             = "@1 Stone Block",
	  sandstone_block         = "@1 Sandstone Block",
	  desert_stone_block      = "@1 Desert Stone Block",
	  desert_sandstone_block  = "@1 Desert Sandstone Block",
	  silver_sandstone_block  = "@1 Silver Sandstone Block",
	  obsidian_block          = "@1 Obsidian Block" }

	  for k, rune_node_description in pairs(node_names) do
		local node_name      = "default:"..k
		local rune_node_name = "ancientrunes:"..k.."_"..r

		minetest.register_node(rune_node_name, {
		  description = S(rune_node_description, rune_description),
		  is_ground_content = false,
		  groups = {cracky = 2},
		  tiles = {"default_"..k..".png^"..rune_image}
		})

		minetest.register_craft({
		  type   = "shapeless",
		  output = rune_node_name,
		  recipe = {node_name, rune_name}
		})
	  end
	end
end

local function register_powder()
	minetest.register_craftitem("ancientrunes:iron_powder", {
	  description = S("Iron Powder"),
	  inventory_image = "ancientrunes_item_iron_powder.png"
	})

	minetest.register_craftitem("ancientrunes:mese_powder", {
	  description = S("Mese Powder"),
	  inventory_image = "ancientrunes_item_mese_powder.png"
	})

	minetest.register_craftitem("ancientrunes:rune_powder", {
	  description = S("Rune Powder"),
	  inventory_image = "ancientrunes_item_rune_powder.png"
	})

	minetest.register_craft({
	  output = "ancientrunes:rune_powder 5",
	  recipe = { { "ancientrunes:iron_powder", "",                         "ancientrunes:iron_powder" },
		         { ""                        , "ancientrunes:mese_powder", ""},
		         { "ancientrunes:iron_powder", "",                         "ancientrunes:iron_powder" } }
	})
end

local function register_rune_crafts()
    local x = "ancientrunes:rune_powder"
    local o = ""

    register_rune_recipe("fehu",
    {x, x, x},
    {x, x, o},
    {x, o, o})

    register_rune_recipe("ur",
    {x, x, o},
    {x, o, x},
    {x, o, x})

    register_rune_recipe("thurisaz",
    {x, o, o},
    {x, x, x},
    {x, o, o})

    register_rune_recipe("ansuz",
    {x, x, o},
    {x, x, x},
    {x, o, o})

    register_rune_recipe("raido",
    {x, x, o},
    {x, x, o},
    {x, o, x})

    register_rune_recipe("kaunan",
    {o, x, x},
    {x, o, o},
    {o, x, x})

    register_rune_recipe("gyfu",
    {x, o, x},
    {o, x, o},
    {x, o, x})

    register_rune_recipe("wynn",
    {x, x, x},
    {x, x, x},
    {x, o, o})

    register_rune_recipe("hagalaz",
    {x, o, x},
    {x, x, x},
    {x, x, x})

    register_rune_recipe("naudiz",
    {x, x, o},
    {o, x, o},
    {o, x, x})

    register_rune_recipe("isaz",
    {o, x, o},
    {o, x, o},
    {o, x, o})

    register_rune_recipe("jera",
    {x, x, o},
    {x, o, x},
    {o, x, x})

    register_rune_recipe("ihwa",
    {o, x, x},
    {o, x, o},
    {x, x, o})

    register_rune_recipe("peorth",
    {x, x, x},
    {x, o, o},
    {x, x, x})

    register_rune_recipe("algiz",
    {x, x, x},
    {x, x, x},
    {o, x, o})

    register_rune_recipe("sowilo",
    {x, x, x},
    {o, x, x},
    {x, x, x})

    register_rune_recipe("tiwaz",
    {x, x, x},
    {o, x, o},
    {o, x, o})

    register_rune_recipe("berkanan",
    {x, x, x},
    {x, x, o},
    {x, x, x})

    register_rune_recipe("ehwaz",
    {x, o, x},
    {x, x, x},
    {x, o, x})

    register_rune_recipe("mannaz",
    {x, x, x},
    {x, x, x},
    {x, o, x})

    register_rune_recipe("laguz",
    {x, x, o},
    {x, o, x},
    {x, o, o})

    register_rune_recipe("yngvi",
    {o, x, o},
    {x, o, x},
    {o, x, o})

    register_rune_recipe("dagaz",
    {x, x, x},
    {x, x, x},
    {x, x, x})

    register_rune_recipe("othala",
    {o, x, o},
    {x, x, x},
    {x, o, x})
end

register_burins()
register_runes()
register_powder()
register_rune_crafts()
