local Travelable = Class(function(self, inst)
    self.inst = inst

    self._infos = net_string(inst.GUID, "travelable._infos")

    self.screen = nil
    self.opentask = nil

    if TheWorld.ismastersim then
        self.classified = SpawnPrefab("travelable_classified")
        self.classified.entity:SetParent(inst.entity)
    else
        if self.classified == nil and inst.travelable_classified ~= nil then
            self.classified = inst.travelable_classified
            inst.travelable_classified.OnRemoveEntity = nil
            inst.travelable_classified = nil
            self:AttachClassified(self.classified)
        end
    end
end)

--------------------------------------------------------------------------

function Travelable:OnRemoveFromEntity()
    if self.classified ~= nil then
        if TheWorld.ismastersim then
            self.classified:Remove()
            self.classified = nil
        else
            self.classified._parent = nil
            self.inst:RemoveEventCallback("onremove", self.ondetachclassified,
                                          self.classified)
            self:DetachClassified()
        end
    end
end

Travelable.OnRemoveEntity = Travelable.OnRemoveFromEntity

--------------------------------------------------------------------------
-- Client triggers writing based on receiving access to classified data
--------------------------------------------------------------------------

local function BeginTravel(inst, self)
    self.opentask = nil
    self:BeginTravel(ThePlayer)
end

function Travelable:AttachClassified(classified)
    self.classified = classified

    self.ondetachclassified = function() self:DetachClassified() end
    self.inst:ListenForEvent("onremove", self.ondetachclassified, classified)

    self.opentask = self.inst:DoTaskInTime(0, BeginTravel, self)
end

function Travelable:DetachClassified()
    self.classified = nil
    self.ondetachclassified = nil
    self:EndTravel()
end

--------------------------------------------------------------------------
-- Common interface
--------------------------------------------------------------------------

function Travelable:BeginTravel(traveller)
    if self.inst.components.travelable ~= nil then
        if self.opentask ~= nil then
            self.opentask:Cancel()
            self.opentask = nil
        end
        self.inst.components.travelable:BeginTravel(traveller)
    elseif self.classified ~= nil and self.opentask == nil and traveller ~= nil and
        traveller == ThePlayer then
        if traveller.HUD == nil then
            -- abort
        else -- if not busy...
            self.screen = traveller.HUD:ShowTravelScreen(self.inst)
        end
    end
end

function Travelable:Travel(traveller, index)
    if self.inst.components.travelable ~= nil then
        self.inst.components.travelable:Travel(traveller, index)
    elseif self.classified ~= nil and traveller == ThePlayer then
        SendModRPCToServer(MOD_RPC.FastTravel.Travel, self.inst, index)
    end
end

function Travelable:EndTravel()
    if self.opentask ~= nil then
        self.opentask:Cancel()
        self.opentask = nil
    end
    if self.inst.components.travelable ~= nil then
        self.inst.components.travelable:EndTravel()
    elseif self.screen ~= nil then
        if ThePlayer ~= nil and ThePlayer.HUD ~= nil then
            ThePlayer.HUD:CloseTravelScreen()
        elseif self.screen.inst:IsValid() then
            -- Should not have screen and no traveller, but just in case...
            self.screen:Kill()
        end
        self.screen = nil
    end
end

function Travelable:SetTraveller(traveller)
    self.classified.Network:SetClassifiedTarget(traveller or self.inst)
    if self.inst.components.travelable == nil then
        -- Should only reach here during travelable construction
        assert(traveller == nil)
    end
end

function Travelable:SetDestInfos(infos) self._infos:set(infos) end

function Travelable:GetDestInfos() return self._infos:value() end

return Travelable
