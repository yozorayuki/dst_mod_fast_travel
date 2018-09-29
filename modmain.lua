local Ownership = GetModConfigData("Ownership")
local Travel_Cost = GetModConfigData("Travel_Cost")
local FTSignTag = 'fast_travel'

local FT_Points = {
	"homesign"
}

for k, v in pairs(FT_Points) do
	AddPrefabPostInit(v,function(inst)
		inst:AddComponent("talker")
		if GLOBAL.TheWorld.ismastersim then
			inst:AddComponent("fasttravel")
			inst.components.fasttravel.dist_cost = Travel_Cost
			inst.components.fasttravel.ownership = Ownership
		end
	end)
end

-- Actions ------------------------------

AddAction("DESTINATION", "Select Destination", function(act)
	if act.doer ~= nil and act.target ~= nil and act.doer:HasTag("player") and act.target.components.fasttravel and not act.target:HasTag("burnt") and not act.target:HasTag("fire") then
		act.target.components.fasttravel:SelectDestination(act.doer)
		return true
	end
end)

-- Component actions ---------------------

AddComponentAction("SCENE", "fasttravel", function(inst, doer, actions, right)
	if right then
		if inst:HasTag(FTSignTag) and not inst:HasTag("burnt") and not inst:HasTag("fire") then
			table.insert(actions, GLOBAL.ACTIONS.DESTINATION)
		end
	end
end)

-- Stategraph ----------------------------

AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(GLOBAL.ACTIONS.DESTINATION, "give"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(GLOBAL.ACTIONS.DESTINATION, "give"))