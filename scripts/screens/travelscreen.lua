local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Text = require "widgets/text"

local TEMPLATES = require "widgets/redux/templates"
local ScrollableList = require "widgets/scrollablelist"

local TravelScreen = Class(Screen, function(self, owner, attach)
    Screen._ctor(self, "TravelSelector")

    self.owner = owner
    self.attach = attach

    self.isopen = false

    self._scrnw, self._scrnh = TheSim:GetScreenSize()

    self:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self:SetMaxPropUpscale(MAX_HUD_SCALE)
    self:SetPosition(0, 0, 0)
    self:SetVAnchor(ANCHOR_MIDDLE)
    self:SetHAnchor(ANCHOR_MIDDLE)

    self.scalingroot = self:AddChild(Widget("travelablewidgetscalingroot"))
    self.scalingroot:SetScale(TheFrontEnd:GetHUDScale())

    self.inst:ListenForEvent("continuefrompause", function()
        if self.isopen then
            self.scalingroot:SetScale(TheFrontEnd:GetHUDScale())
        end
    end, TheWorld)
    self.inst:ListenForEvent("refreshhudsize", function(hud, scale)
        if self.isopen then self.scalingroot:SetScale(scale) end
    end, owner.HUD.inst)

    self.root = self.scalingroot:AddChild(TEMPLATES.ScreenRoot("root"))

    -- secretly this thing is a modal Screen, it just LOOKS like a widget
    self.black = self.root:AddChild(Image("images/global.xml", "square.tex"))
    self.black:SetVRegPoint(ANCHOR_MIDDLE)
    self.black:SetHRegPoint(ANCHOR_MIDDLE)
    self.black:SetVAnchor(ANCHOR_MIDDLE)
    self.black:SetHAnchor(ANCHOR_MIDDLE)
    self.black:SetScaleMode(SCALEMODE_FILLSCREEN)
    self.black:SetTint(0, 0, 0, 0)
    self.black.OnMouseButton = function() self:OnCancel() end

    self.destspanel = self.root:AddChild(TEMPLATES.RectangleWindow(350, 550))
    self.destspanel:SetPosition(0, 25)

    self.current = self.destspanel:AddChild(Text(BODYTEXTFONT, 35))
    self.current:SetPosition(0, 250, 0)
    self.current:SetRegionSize(350, 50)
    self.current:SetHAlign(ANCHOR_MIDDLE)

    self.cancelbutton = self.destspanel:AddChild(
                            TEMPLATES.StandardButton(
                                function() self:OnCancel() end, "Cancel",
                                {120, 40}))
    self.cancelbutton:SetPosition(0, -250)

    self:LoadDests()
    self:Show()
    self.default_focus = self.dests_scroll_list
    self.isopen = true
end)

function TravelScreen:LoadDests()
    local info_pack = self.attach.replica.travelable and
                          self.attach.replica.travelable:GetDestInfos()
    self.dest_infos = {}
    for i, v in ipairs(string.split(info_pack, "\n")) do
        local elements = string.split(v, "\t")
        if elements[1] == tostring(i) then
            local info = {}
            info.index = i
            info.name = elements[2]
            if info.name == "~nil" then info.name = nil end
            info.cost_hunger = tonumber(elements[3]) or -2
            info.cost_sanity = tonumber(elements[4]) or -2
            table.insert(self.dest_infos, info)
        else
            print("data error:\n", info_pack)
            self.isopen = true
            self:OnCancel()
            return
        end
    end

    self:RefreshDests()
end

function TravelScreen:RefreshDests()
    self.destwidgets = {}
    for i, v in ipairs(self.dest_infos) do
        local data = {index = i, info = v}

        table.insert(self.destwidgets, data)
    end

    local function ScrollWidgetsCtor(context, index)
        local widget = Widget("widget-" .. index)

        widget:SetOnGainFocus(function()
            self.dests_scroll_list:OnWidgetFocus(widget)
        end)

        widget.destitem = widget:AddChild(self:DestListItem())
        local dest = widget.destitem

        widget.focus_forward = dest

        return widget
    end

    local function ApplyDataToWidget(context, widget, data, index)
        widget.data = data
        widget.destitem:Hide()
        if not data then
            widget.focus_forward = nil
            return
        end

        widget.focus_forward = widget.destitem
        widget.destitem:Show()

        local dest = widget.destitem

        dest:SetInfo(data.info)
    end

    if not self.dests_scroll_list then
        self.dests_scroll_list = self.destspanel:AddChild(
                                     TEMPLATES.ScrollingGrid(self.destwidgets, {
                context = {},
                widget_width = 350,
                widget_height = 90,
                num_visible_rows = 5,
                num_columns = 1,
                item_ctor_fn = ScrollWidgetsCtor,
                apply_fn = ApplyDataToWidget,
                scrollbar_offset = 10,
                scrollbar_height_offset = -60,
                peek_percent = 0, -- may init with few clientmods, but have many servermods.
                allow_bottom_empty_row = true -- it's hidden anyway
            }))

        self.dests_scroll_list:SetPosition(0, 0)

        self.dests_scroll_list:SetFocusChangeDir(MOVE_DOWN, self.cancelbutton)
        self.cancelbutton:SetFocusChangeDir(MOVE_UP, self.dests_scroll_list)
    end
end

function TravelScreen:DestListItem()
    local dest = Widget("destination")

    local item_width, item_height = 340, 90
    dest.backing = dest:AddChild(TEMPLATES.ListItemBackground(item_width,
                                                              item_height,
                                                              function() end))
    dest.backing.move_on_click = true

    dest.name = dest:AddChild(Text(BODYTEXTFONT, 35))
    dest.name:SetVAlign(ANCHOR_MIDDLE)
    dest.name:SetHAlign(ANCHOR_LEFT)
    dest.name:SetPosition(0, 10, 0)
    dest.name:SetRegionSize(300, 40)

    local cost_py = -20
    local cost_font = UIFONT
    local cost_fontsize = 20

    dest.cost_hunger = dest:AddChild(Text(cost_font, cost_fontsize))
    dest.cost_hunger:SetVAlign(ANCHOR_MIDDLE)
    dest.cost_hunger:SetHAlign(ANCHOR_LEFT)
    dest.cost_hunger:SetPosition(-100, cost_py, 0)
    dest.cost_hunger:SetRegionSize(100, 30)

    dest.cost_sanity = dest:AddChild(Text(cost_font, cost_fontsize))
    dest.cost_sanity:SetVAlign(ANCHOR_MIDDLE)
    dest.cost_sanity:SetHAlign(ANCHOR_LEFT)
    dest.cost_sanity:SetPosition(-30, cost_py, 0)
    dest.cost_sanity:SetRegionSize(100, 30)

    dest.status = dest:AddChild(Text(cost_font, cost_fontsize))
    dest.status:SetVAlign(ANCHOR_MIDDLE)
    dest.status:SetHAlign(ANCHOR_LEFT)
    dest.status:SetPosition(150, cost_py, 0)
    dest.status:SetRegionSize(100, 30)

    dest.SetInfo = function(_, info)
        if info.name and info.name ~= "" then
            dest.name:SetString(info.name)
            dest.name:SetColour(1, 1, 1, 1)
        else
            dest.name:SetString("Unknow")
            dest.name:SetColour(1, 1, 0, 0.6)
        end

        dest.cost_hunger:Show()
        dest.cost_hunger:SetString("hunger: " .. math.ceil(info.cost_hunger))
        dest.cost_hunger:SetColour(1, 1, 1, 0.8)

        dest.cost_sanity:Show()
        dest.cost_sanity:SetString("sanity: " .. math.ceil(info.cost_sanity))
        dest.cost_sanity:SetColour(1, 1, 1, 0.8)

        if info.cost_hunger < 0 or info.cost_sanity < 0 then
            dest.backing:SetOnClick(nil)
            if info.cost_hunger < -1 or info.cost_sanity < -1 then
                dest.name:SetColour(1, 0, 0, 0.4)
                dest.cost_hunger:SetColour(1, 0, 0, 0.4)
                dest.cost_sanity:SetColour(1, 0, 0, 0.4)
            else
                dest.name:SetColour(0, 1, 0, 0.6)
                dest.cost_hunger:SetString("current")
                dest.cost_hunger:SetColour(0, 1, 0, 0.4)
                dest.cost_sanity:Hide()

                if info.name and info.name ~= "" then
                    self.current:SetString(info.name)
                    self.current:SetColour(1, 1, 1, 1)
                else
                    self.current:SetString("Unknow")
                    self.current:SetColour(1, 0, 0, 0.4)
                end
            end
        else
            dest.backing:SetOnClick(function()
                self:Travel(info.index)
            end)
        end
    end

    dest.focus_forward = dest.backing
    return dest
end

function TravelScreen:Travel(index)
    if not self.isopen then return end

    local travelable = self.attach.replica.travelable
    if travelable then travelable:Travel(self.owner, index) end

    self.owner.HUD:CloseTravelScreen()
end

function TravelScreen:OnCancel()
    if not self.isopen then return end

    local travelable = self.attach.replica.travelable
    if travelable then travelable:Travel(self.owner, nil) end

    self.owner.HUD:CloseTravelScreen()
end

function TravelScreen:OnControl(control, down)
    if TravelScreen._base.OnControl(self, control, down) then return true end

    if not down then
        if control == CONTROL_OPEN_DEBUG_CONSOLE then
            return true
        elseif control == CONTROL_CANCEL then
            self:OnCancel()
        end
    end
end

function TravelScreen:Close()
    if self.isopen then
        self.attach = nil
        self.black:Kill()
        self.isopen = false

        self.inst:DoTaskInTime(.2, function() TheFrontEnd:PopScreen(self) end)
    end
end

return TravelScreen
