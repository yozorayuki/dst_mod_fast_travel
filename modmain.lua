local require = GLOBAL.require
local TravelScreen = require "screens/travelscreen"

PrefabFiles = {
	"travelable_classified"
}

local Ownership = GetModConfigData("Ownership")
local Travel_Cost = GetModConfigData("Travel_Cost")

local FT_Points = {
	"homesign"
}

AddReplicableComponent("travelable")
for k, v in pairs(FT_Points) do
	AddPrefabPostInit(
		v,
		function(inst)
			inst:AddComponent("talker")
			inst:AddTag("_travelable")
			if GLOBAL.TheWorld.ismastersim then
				inst:RemoveTag("_travelable")
				inst:AddComponent("travelable")
				inst.components.travelable.dist_cost = Travel_Cost
				inst.components.travelable.ownership = Ownership
			end
		end
	)
end

-- Mod RPC ------------------------------
AddModRPCHandler(
	"FastTravel",
	"Travel",
	function(player, inst, index)
		local travelable = inst.components.travelable
		if travelable ~= nil then
			travelable:Travel(player, index)
		end
	end
)

-- PlayerHud UI -------------------------

AddClassPostConstruct(
	"screens/playerhud",
	function(self, anim, owner)
		self.ShowTravelScreen = function(_, attach)
			if attach == nil then
				return
			else
				self.travelscreen = TravelScreen(self.owner, attach)
				self:OpenScreenUnderPause(self.travelscreen)
				return self.travelscreen
			end
		end

		self.CloseTravelScreen = function(_)
			if self.travelscreen then
				self.travelscreen:Close()
				self.travelscreen = nil
			end
		end
	end
)

-- Actions ------------------------------

AddAction(
	"DESTINATION_UI",
	"Select Destination",
	function(act)
		if act.doer ~= nil and act.target ~= nil and act.doer:HasTag("player") and act.target.components.travelable and not act.target:HasTag("burnt") and not act.target:HasTag("fire") then
			act.target.components.travelable:BeginTravel(act.doer)
			return true
		end
	end
)
GLOBAL.ACTIONS.DESTINATION_UI.priority = 1

-- Component actions ---------------------

AddComponentAction(
	"SCENE",
	"travelable",
	function(inst, doer, actions, right)
		if right then
			if not inst:HasTag("burnt") and not inst:HasTag("fire") then
				table.insert(actions, GLOBAL.ACTIONS.DESTINATION_UI)
			end
		end
	end
)

-- Stategraph ----------------------------

AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(GLOBAL.ACTIONS.DESTINATION_UI, "give"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(GLOBAL.ACTIONS.DESTINATION_UI, "give"))
