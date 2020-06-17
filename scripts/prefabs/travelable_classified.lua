--------------------------------------------------------------------------
-- Client interface
--------------------------------------------------------------------------
local function OnRemoveEntity(inst)
    if inst._parent ~= nil then inst._parent.travelable_classified = nil end
end

local function OnEntityReplicated(inst)
    inst._parent = inst.entity:GetParent()
    if inst._parent == nil then
        print("Unable to initialize classified data for travelable")
    elseif inst._parent.replica.travelable ~= nil then
        inst._parent.replica.travelable:AttachClassified(inst)
    else
        inst._parent.travelable_classified = inst
        inst.OnRemoveEntity = OnRemoveEntity
    end
end

--------------------------------------------------------------------------

local function fn()
    local inst = CreateEntity()

    if TheWorld.ismastersim then
        inst.entity:AddTransform() -- So we can follow parent's sleep state
    end
    inst.entity:AddNetwork()
    inst.entity:Hide()
    inst:AddTag("CLASSIFIED")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        -- Client interface
        inst.OnEntityReplicated = OnEntityReplicated

        return inst
    end

    inst.persists = false

    return inst
end

return Prefab("travelable_classified", fn)
