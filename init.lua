local names = {
	pick = "gold_tools:pick",
	axe = "gold_tools:axe",
	shovel = "gold_tools:shovel",
	sword = "gold_tools:sword"
}
local gold = "default:gold_ingot"
local stick = "group:stick"
local times = {[1]=8.0, [2]=6.0, [3]=4.0}

minetest.register_tool(names.pick, {
	description = "Gold Pick",
	inventory_image = "default_tool_goldpick.png",
	tool_capabilities = {
		full_punch_interval = 1.0,
		max_drop_level=3,
		groupcaps={
			cracky={times=times, uses=5, maxlevel=3, dropbonus=1, randomdropbonus=1}
		}
	},
})

minetest.register_craft({
	output = names.pick,
	recipe = {
		{gold, gold, gold},
		{'', stick, ''},
		{'', stick, ''},
	}
})

minetest.register_tool(names.shovel, {
	description = "Gold Shovel",
	inventory_image = "default_tool_goldshovel.png",
	tool_capabilities = {
		max_drop_level=0,
		groupcaps={
			crumbly={times=times, uses=5, maxlevel=3, dropbonus=1, randomdropbonus=1}
		}
	},
})

minetest.register_craft({
	output = names.shovel,
	recipe = {
		{gold},
		{stick},
		{stick},
	}
})

minetest.register_tool(names.axe, {
	description = "Gold Axe",
	inventory_image = "default_tool_goldaxe.png",
	tool_capabilities = {
		max_drop_level=0,
		groupcaps={
			choppy={times=times, uses=5, maxlevel=3, dropbonus=1, randomdropbonus=1}
		}
	},
})

minetest.register_craft({
	output = names.axe,
	recipe = {
		{gold, gold},
		{gold, stick},
		{'',   stick},
	}
})

minetest.register_tool(names.sword, {
	description = "Gold Sword",
	inventory_image = "default_tool_goldsword.png",
	tool_capabilities = {
		full_punch_interval = 1.0,
		max_drop_level=0,
		groupcaps={
			fleshy={times=times, uses=5, maxlevel=3, dropbonus=1, randomdropbonus=1},
			snappy={times={[2]=1.0, [3]=0.60}, uses=5, maxlevel=3, dropbonus=1, randomdropbonus=1},
		}
	}
})

minetest.register_craft({
	output = names.sword,
	recipe = {
		{gold},
		{gold},
		{stick},
	}
})

-- Memoize results so we don't have to recompute on every dig
local disable_duplicates = {
	["farming:beanpole"] = true, 
	["farming:trellis"]  = true 
}
function is_not_duplicable(drop_name)
	if disable_duplicates[drop_name] == nil then
		disable_duplicates[drop_name] = (
			minetest.get_item_group(drop_name, "no_bonus_yield") > 0
			or minetest.get_item_group(drop_name, "technic_machine") > 0
			or string.match(drop_name, "%d$") -- Ends in a number
			or string.match(drop_name, "off$") -- Ends in "off"
			or string.match(drop_name, "idle$") -- Ends in "idle"
			or string.match(drop_name, "inactive$") -- Ends in "inactive"
		)
	end
	return disable_duplicates[drop_name]
end

-- Save the native dig function.
local native_dig = minetest.node_dig

-- Restores wear-and-tear when using custom dig logic.
function handle_wear(digger, uses)
	local tool = digger:get_wielded_item()
	local item_wear = tonumber(tool:get_wear())
	item_wear = item_wear + (65535 / (uses * 3))
	if item_wear > 65535 then
		tool:clear()
	else
		tool:set_wear(item_wear)
	end
	digger:set_wielded_item(tool)
end

local special_drops = {
	["maple_tree:trunk"] = {"maple_tree:syrup", "maple_tree:trunk_tapped"},
	["big_trees:ironwood"] = {"default:iron_lump"},
	["big_trees:diamondwood"] = {"default:diamond"},
	["big_trees:bark"] = {"default:sand"}
}
if minetest.get_modpath("technic") then
	special_drops["moretrees:rubber_tree_trunk"] = {"technic:raw_latex", "moretrees:rubber_tree_trunk_empty"}
end

function handle_bonus_yields(pos, oldnode, digger, tool, bonus, uses)
	if special_drops[oldnode.name] then
		for d, drop_item in ipairs(special_drops[oldnode.name]) do
			-- Only the first yield gets the bonus effect
			local yield = (d > 1 and 1) or (bonus+1)
			for drop_count = 1, yield do
				minetest.handle_node_drops(pos, {drop_item}, digger)
			end
		end
		minetest.swap_node(pos, {name = "air"})
		handle_wear(digger, uses)
		return
	end
	-- Convert "normal" trees into wood if possible
	if minetest.get_item_group(oldnode.name, "tree") > 0 then
		local output = minetest.get_craft_result({ method = "normal", width = 1, items = { oldnode.name }}).item
		if output:get_name() ~= "" then
			local yield = (bonus+1) * output:get_count()
			for drop_count = 1, yield do
				minetest.handle_node_drops(pos, {output:get_name()}, digger)
			end
			minetest.swap_node(pos, {name = "air"})
			handle_wear(digger, uses)
			return
		end
	end
	-- Default behavior
	for drop_i, drop_name in ipairs(minetest.get_node_drops(oldnode.name, tool)) do
		-- Allow disabling bonus yields and prevent node duplication.
		if not (
			drop_name == oldnode.name
			or is_not_duplicable(drop_name)
		) then 
			for drop_count = 1, bonus do
				minetest.handle_node_drops(pos, {drop_name}, digger)
			end
		end
	end
	return native_dig(pos, oldnode, digger)
end

minetest.node_dig = function(pos, oldnode, digger)
	if digger and not minetest.is_protected(pos, digger:get_player_name()) then
		local tool = digger:get_wielded_item()
		local tooldef = minetest.registered_tools[tool:get_name()]
		if tooldef and tooldef.tool_capabilities then
			local groupcaps = tooldef.tool_capabilities.groupcaps
			if groupcaps then
				for cap,props in pairs(groupcaps) do
					if minetest.get_item_group(oldnode.name, cap) > 0 then
						local bonus = (props.dropbonus or 0)+math.random(0, props.randomdropbonus or 0)
						if math.floor(bonus) > 0 then
							return handle_bonus_yields(pos, oldnode, digger, tool, bonus, props.uses)
						end
					end
				end
			end
		end
	end
	return native_dig(pos,oldnode, digger)
end
