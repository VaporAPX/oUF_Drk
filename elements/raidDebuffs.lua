local _, ns = ...
local cfg = ns.cfg
local lib = ns.lib
local oUF = ns.oUF or oUF

local candispell = {
	Magic = {
		["Holy"] = true,
		["Mistweaver"] = true,
	},
	Curse = {
		
	},
	Disease = {
		["Mistweaver"] = true,
	},
	Poison = {
		["Mistweaver"] = true,
	}
}

local border
local backdrop_tab = { 
	bgFile = cfg.backdrop_texture, 
	edgeFile = cfg.backdrop_edge_texture,
	tile = false,
	tileSize = 0, 
	edgeSize = 5, 
	insets = { 
		left = 3, 
		right = 3, 
		top = 3, 
		bottom = 3,
	},
}
local gen_backdrop = function(f,r,g,b)
	f:SetBackdrop(backdrop_tab);
	f:SetBackdropColor(r,g,b,1)
	f:SetBackdropBorderColor(r,g,b,0.8)
end

local createAuraIcon = function(debuffs)
	local button = CreateFrame("Button", nil, debuffs)
	button:EnableMouse(false)
	button:SetFrameLevel(5)
	
	button:SetSize(debuffs.size, debuffs.size)

	local icon = button:CreateTexture(nil, "BACKGROUND")

	--icon:SetAllPoints(button)
	icon:SetPoint("TOPLEFT",button,"TOPLEFT",-1,1)
	icon:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",1.3,-1.3)
	icon:SetTexCoord(.15, .8, .15, .8)
	
	border = CreateFrame("Frame", nil, button)
	border:SetFrameLevel(4)
	border:SetPoint("TOPLEFT",-7,6)
	border:SetPoint("BOTTOMRIGHT",6,-7)
	gen_backdrop(border,0,0,0)
	
	
	local count = button:CreateFontString(nil, "OVERLAY")
	count:SetFont(cfg.smallfont,9,"OUTLINE")
	count:SetShadowColor(0,0,0,0.8)
	count:SetShadowOffset(1,-1)
	count:SetPoint("LEFT", button, "BOTTOM", 0, 4)

	local overlay = button:CreateTexture(nil, "OVERLAY")
	overlay:SetTexture(cfg.debuff_border_texture)
	overlay:SetPoint("TOPLEFT", button, "TOPLEFT", -3, 2)
	overlay:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
	overlay:SetTexCoord(0.03, 0.97, 0.03, 0.97)
	button.overlay = overlay
	
	button:SetPoint("BOTTOMLEFT", debuffs, "BOTTOMLEFT")
	
	button.parent = debuffs
	button.icon = icon
	button.count = count
	button:Hide()
	
	debuffs.button = button
end

local updateDebuff = function(icon, texture, count, dtype, duration, timeLeft)
	local color = DebuffTypeColor[dtype] or DebuffTypeColor.none

	icon.overlay:SetVertexColor(color.r,color.g,color.b)
	icon.overlay:Show()

	icon.icon:SetTexture(texture)
	icon.count:SetText((count > 1 and count))
end

local updateIcon = function(unit, debuffs)
	local cur
	local hide = true
	local index = 1
	while true do
		--local name, rank, texture, count, dtype, duration, timeLeft, caster, isStealable, shouldConsolidate, spellID = UnitAura(unit, index, 'HARMFUL')
		local name, rank, texture, count, dtype, duration, timeLeft, caster, isStealable, shouldConsolidate, spellID = UnitAura(unit, index, 'HARMFUL')
		if not name then break end
		
		local icon = debuffs.button
		local show = debuffs.CustomFilter(debuffs, unit, icon, name, rank, texture, count, dtype, duration, timeLeft, caster, isStealable, shouldConsolidate, spellID)
		
		if not show then
			if dtype and candispell[dtype][cfg.spec] then
				show = true
				icon.priority = 5
			end
		end
		
		if(show) then
			if not cur then
				cur = icon.priority
				updateDebuff(icon, texture, count, dtype, duration, timeLeft)
			else
				if icon.priority > cur then
					updateDebuff(icon, texture, count, dtype, duration, timeLeft)
				end
			end
			
			icon:Show()
			hide = false
		end

		index = index + 1
	end
	if hide then
		debuffs.button:Hide()
	end
end

local Update = function(self, event, unit)
	if(self.unit ~= unit) then return end

	local debuffs = self.raidDebuffs
	if(debuffs) then
		updateIcon(unit, debuffs)
	end
end

local Enable = function(self)
	if(self.raidDebuffs) then
		createAuraIcon(self.raidDebuffs)
		cfg.updateSpec()
		self:RegisterEvent("UNIT_AURA", Update)
		return true
	end
end

local Disable = function(self)
	if(self.raidDebuffs) then
		self:UnregisterEvent("UNIT_AURA", Update)
		--self:UnregisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	end
end

oUF:AddElement('raidDebuffs', Update, Enable, Disable)