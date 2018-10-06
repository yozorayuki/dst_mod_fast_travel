local function ontraveller(self, traveller)
	self.inst.replica.travelable:SetTraveller(traveller)
end

local default_dist_cost = 32
local max_sanity_cost = 15
local min_hunger_cost = 5
local sanity_cost_ratio = 20 / 75
local find_dist = (max_sanity_cost / sanity_cost_ratio - min_hunger_cost) * default_dist_cost

local ownershiptag = "uid_private"

local Travelable =
	Class(
	function(self, inst)
		self.inst = inst
		self.inst:AddTag("travelable")

		self.dist_cost = default_dist_cost
		self.traveller = nil
		self.destinations = {}
		self.travellers = {}

		self.onclosepopups = function(traveller) -- yay closures ~gj -- yay ~v2c
			if traveller == self.traveller then
				self:EndTravel()
			end
		end

		self.generatorfn = nil
	end,
	nil,
	{
		traveller = ontraveller
	}
)

local function IsNearDanger(traveller)
	local hounded = TheWorld.components.hounded
	if hounded ~= nil and (hounded:GetWarning() or hounded:GetAttacking()) then
		return true
	end
	local burnable = traveller.components.burnable
	if burnable ~= nil and (burnable:IsBurning() or burnable:IsSmoldering()) then
		return true
	end
	if traveller:HasTag("spiderwhisperer") then
		return FindEntity(
			traveller,
			10,
			function(target)
				return (target.components.combat ~= nil and target.components.combat.target == traveller) or (not (target:HasTag("player") or target:HasTag("spider")) and (target:HasTag("monster") or target:HasTag("pig")))
			end,
			nil,
			nil,
			{"monster", "pig", "_combat"}
		) ~= nil
	end
	return FindEntity(
		traveller,
		10,
		function(target)
			return (target.components.combat ~= nil and target.components.combat.target == traveller) or (target:HasTag("monster") and not target:HasTag("player"))
		end,
		nil,
		nil,
		{"monster", "_combat"}
	) ~= nil
end

function Travelable:ListDestination(traveller)
	local x, y, z = self.inst.Transform:GetWorldPosition()
	local dests = TheSim:FindEntities(x, y, z, find_dist, "travelable")
	self.destinations = {}

	for k, v in pairs(dests) do
		if v.components.travelable and not (v.components.travelable.ownership and v:HasTag(ownershiptag) and traveller.userid ~= nil and not v:HasTag("uid_" .. traveller.userid)) then
			table.insert(self.destinations, v)
		end
	end

	table.sort(
		self.destinations,
		function(destA, destB)
			local writeA = destA.components.writeable
			local writeB = destB.components.writeable
			if writeA == nil or writeA:GetText() == nil or writeA:GetText() == "" then
				return false
			end
			if writeB == nil or writeB:GetText() == nil or writeB:GetText() == "" then
				return true
			end
			return string.lower(writeA:GetText()) < string.lower(writeB:GetText())
		end
	)

	self.totalsites = #self.destinations
	self.site = self.totalsites
end

function Travelable:BeginTravel(traveller)
	local comment = self.inst.components.talker
	if not traveller then
		if comment then
			comment:Say("Who touched me?")
		end
		return
	end
	local talk = traveller.components.talker

	if self.ownership and self.inst:HasTag(ownershiptag) and traveller.userid ~= nil and not self.inst:HasTag("uid_" .. traveller.userid) then
		if comment then
			comment:Say("Private property.")
		elseif talk then
			talk:Say("This post is a private property.")
		end
		return
	elseif self.traveller then
		if comment then
			comment:Say("It's not your turn.")
		elseif talk then
			talk:Say("It's not my turn.")
		end
		return
	elseif IsNearDanger(traveller) then
		if talk then
			talk:Say("It's not safe to travel.")
		elseif comment then
			comment:Say("It's not safe to travel.")
		end
		return
	end

	local isintask = false
	for k, v in pairs(self.travellers) do
		if v == traveller then
			isintask = true
		end
	end

	if not self.traveltask or isintask then
		self.inst:StartUpdatingComponent(self)

		self:ListDestination(traveller)
		self:MakeInfos()
		self:CancelTravel(traveller)
		self.travellers = {}

		self.traveller = traveller
		self.inst:ListenForEvent("ms_closepopups", self.onclosepopups, traveller)
		self.inst:ListenForEvent("onremove", self.onclosepopups, traveller)

		if traveller.HUD ~= nil then
			self.screen = traveller.HUD:ShowTravelScreen(self.inst)
		end
	else
		self:CancelTravel(traveller)
		self:Travel(traveller, self.site)
	end
end

function Travelable:MakeInfos()
	local infos = ""
	for k, destination in ipairs(self.destinations) do
		local name = destination.components.writeable and destination.components.writeable:GetText() or ""
		local cost_hunger = min_hunger_cost
		local cost_sanity = 0
		local xi, yi, zi = self.inst.Transform:GetWorldPosition()
		local xf, yf, zf = destination.Transform:GetWorldPosition()
		local dist = math.sqrt((xi - xf) ^ 2 + (zi - zf) ^ 2)

		cost_hunger = cost_hunger + math.ceil(dist / self.dist_cost)
		cost_sanity = cost_hunger * sanity_cost_ratio
		if TheWorld.state.season == "winter" then
			cost_sanity = cost_sanity * 1.25
		elseif TheWorld.state.season == "summer" then
			cost_sanity = cost_sanity * 0.75
		end

		if destination == self.inst then
			cost_hunger = 0
			cost_sanity = 0
		end

		infos = infos .. (infos == "" and "" or "\n") .. name .. "\t" .. cost_hunger .. "\t" .. cost_sanity
	end
	self.inst.replica.travelable:SetDestInfos(infos)
end

function Travelable:Travel(traveller, index)
	local destination = self.destinations[index]
	if traveller and destination then
		self.site = index
		local comment = self.inst.components.talker
		local talk = traveller.components.talker

		-- Site information
		local desc = destination and destination.components.writeable and destination.components.writeable:GetText()
		local description = desc and string.format('"%s"', desc) or "Unknown Destination"
		local information = ""
		local cost_hunger = min_hunger_cost
		local cost_sanity = 0
		local xi, yi, zi = self.inst.Transform:GetWorldPosition()
		local xf, yf, zf = destination.Transform:GetWorldPosition()
		local dist = math.sqrt((xi - xf) ^ 2 + (zi - zf) ^ 2)

		if destination and destination.components.travelable then
			table.insert(self.travellers, traveller)

			cost_hunger = cost_hunger + math.ceil(dist / self.dist_cost)
			cost_sanity = cost_hunger * sanity_cost_ratio
			if TheWorld.state.season == "winter" then
				cost_sanity = cost_sanity * 1.25
			elseif TheWorld.state.season == "summer" then
				cost_sanity = cost_sanity * 0.75
			end

			information = "To: " .. description .. " (" .. string.format("%.0f", self.site) .. "/" .. string.format("%.0f", self.totalsites) .. ")" .. "\n" .. "Hunger Cost: " .. string.format("%.0f", cost_hunger) .. "\n" .. "Sanity Cost: " .. string.format("%.1f", cost_sanity)
			if comment then
				comment:Say(string.format(information), 3)
			elseif talk then
				talk:Say(string.format(information), 3)
			end

			self.traveltask =
				self.inst:DoTaskInTime(
				8,
				function()
					self.traveltask = nil
					for k, who in pairs(self.travellers) do
						if destination == nil or not destination:IsValid() then
							if comment then
								comment:Say("The destination is no longer reachable.")
							elseif talk then
								talk:Say("The destination is no longer reachable.")
							end
						elseif who == nil or (who.components.health and who.components.health:IsDead()) then
							if comment then
								comment:Say("We don't ship dead bodies.")
							end
						elseif not who:IsNear(self.inst, 10) then
						elseif IsNearDanger(who) then
							if talk then
								talk:Say("It's not safe to travel.")
							elseif comment then
								comment:Say("It's not safe to travel.")
							end
						elseif destination.components.travelable.ownership and destination:HasTag(ownershiptag) and who.userid ~= nil and not destination:HasTag("uid_" .. who.userid) then
							if comment then
								comment:Say("Private destination. No visitors.")
							elseif talk then
								talk:Say("The destination is private.")
							end
						elseif who.components.hunger and who.components.hunger.current >= cost_hunger and who.components.sanity and who.components.sanity.current >= cost_sanity then
							-- /follow
							who.components.hunger:DoDelta(-cost_hunger)
							who.components.sanity:DoDelta(-cost_sanity)
							if who.Physics ~= nil then
								who.Physics:Teleport(xf - 1, 0, zf)
							else
								who.Transform:SetPosition(xf - 1, 0, zf)
							end

							-- follow
							if who.components.leader and who.components.leader.followers then
								for kf, vf in pairs(who.components.leader.followers) do
									if kf.Physics ~= nil then
										kf.Physics:Teleport(xf + 1, 0, zf)
									else
										kf.Transform:SetPosition(xf + 1, 0, zf)
									end
								end
							end

							local inventory = who.components.inventory
							if inventory then
								for ki, vi in pairs(inventory.itemslots) do
									if vi.components.leader and vi.components.leader.followers then
										for kif, vif in pairs(vi.components.leader.followers) do
											if kif.Physics ~= nil then
												kif.Physics:Teleport(xf, 0, zf + 1)
											else
												kif.Transform:SetPosition(xf, 0, zf + 1)
											end
										end
									end
								end
							end

							local container = inventory:GetOverflowContainer()
							if container then
								for kb, vb in pairs(container.slots) do
									if vb.components.leader and vb.components.leader.followers then
										for kbf, vbf in pairs(vb.components.leader.followers) do
											if kbf.Physics ~= nil then
												kbf.Physics:Teleport(xf, 0, zf - 1)
											else
												kbf.Transform:SetPosition(xf, 0, zf - 1)
											end
										end
									end
								end
							end
						else
							if talk then
								talk:Say("I won't make it.")
							elseif comment then
								comment:Say("You won't make it.")
							end
						end
					end
					self.travellers = {}
				end
			)

			self.traveltask5 =
				self.inst:DoTaskInTime(
				3,
				function()
					comment:Say("Travel in 5 seconds.")
				end
			)
			self.traveltask4 =
				self.inst:DoTaskInTime(
				4,
				function()
					comment:Say("Stay close.")
					self.inst.SoundEmitter:PlaySound("dontstarve/HUD/craft_down")
				end
			)
			self.traveltask3 =
				self.inst:DoTaskInTime(
				5,
				function()
					comment:Say("Travel in 3 seconds.")
					self.inst.SoundEmitter:PlaySound("dontstarve/HUD/craft_down")
				end
			)
			self.traveltask2 =
				self.inst:DoTaskInTime(
				6,
				function()
					comment:Say("Travel in 2 seconds.")
					self.inst.SoundEmitter:PlaySound("dontstarve/HUD/craft_down")
				end
			)
			self.traveltask1 =
				self.inst:DoTaskInTime(
				7,
				function()
					comment:Say("Travel in 1 second.", 1)
					self.inst.SoundEmitter:PlaySound("dontstarve/HUD/craft_down")
				end
			)
		elseif comment then
			comment:Say("The destination is unreachable.")
		elseif talk then
			talk:Say("The destination is unreachable.")
		end
	end
	self:EndTravel()
end

function Travelable:CancelTravel(traveller)
	if self.traveltask ~= nil then
		self.traveltask:Cancel()
		self.traveltask = nil
	end
	if self.traveltask1 ~= nil then
		self.traveltask1:Cancel()
		self.traveltask1 = nil
	end
	if self.traveltask2 ~= nil then
		self.traveltask2:Cancel()
		self.traveltask2 = nil
	end
	if self.traveltask3 ~= nil then
		self.traveltask3:Cancel()
		self.traveltask3 = nil
	end
	if self.traveltask4 ~= nil then
		self.traveltask4:Cancel()
		self.traveltask4 = nil
	end
	if self.traveltask5 ~= nil then
		self.traveltask5:Cancel()
		self.traveltask5 = nil
	end
end

function Travelable:EndTravel()
	if self.traveller ~= nil then
		self.inst:StopUpdatingComponent(self)

		if self.screen ~= nil then
			self.traveller.HUD:CloseTravelScreen()
			self.screen = nil
		end

		self.inst:RemoveEventCallback("ms_closepopups", self.onclosepopups, self.traveller)
		self.inst:RemoveEventCallback("onremove", self.onclosepopups, self.traveller)

		if IsXB1() then
			if self.traveller:HasTag("player") and self.traveller:GetDisplayName() then
				local ClientObjs = TheNet:GetClientTable()
				if ClientObjs ~= nil and #ClientObjs > 0 then
					for i, v in ipairs(ClientObjs) do
						if self.traveller:GetDisplayName() == v.name then
							self.netid = v.netid
							break
						end
					end
				end
			end
		end

		self.traveller = nil
	elseif self.screen ~= nil then
		--Should not have screen and no traveller, but just in case...
		if self.screen.inst:IsValid() then
			self.screen:Kill()
		end
		self.screen = nil
	end
end

--------------------------------------------------------------------------
--Check for auto-closing conditions
--------------------------------------------------------------------------

function Travelable:OnUpdate(dt)
	if self.traveller == nil then
		self.inst:StopUpdatingComponent(self)
	elseif (self.traveller.components.rider ~= nil and self.traveller.components.rider:IsRiding()) or not (self.traveller:IsNear(self.inst, 3) and CanEntitySeeTarget(self.traveller, self.inst)) then
		self:EndTravel()
	end
end

--------------------------------------------------------------------------

function Travelable:OnRemoveFromEntity()
	self:EndTravel()
	self.inst:RemoveTag("travelable")
end

Travelable.OnRemoveEntity = Travelable.EndTravel

return Travelable
