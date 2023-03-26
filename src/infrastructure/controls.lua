local WM = WINDOW_MANAGER

IE_CONTROLS = {
	Controls = {}
}

function IE_CONTROLS.SetTooltip(control, tooltip)
	if tooltip ~=nil then
		control:SetHandler("OnMouseEnter", function(ctrl) ZO_Tooltips_ShowTextTooltip(ctrl, TOP, tooltip) end)
		control:SetHandler("OnMouseExit", function(ctrl) ZO_Tooltips_HideTextTooltip() end)
	else
		control:SetHandler("OnMouseEnter", nil)
		control:SetHandler("OnMouseExit", nil)
	end
end

function IE_CONTROLS.Label(name, parent, dims, anchor, font, color, align, text, hidden, tooltip)
	--Validate arguments
--	if (name==nil or name=="") then return end
	parent=(parent==nil) and GuiRoot or parent
	if (#anchor~=4 and #anchor~=5) then return end
	font	=(font==nil) and "ZoFontGame" or font
	color	=(color~=nil and #color==4) and color or {1,1,1,1}
	align	=(align~=nil and #align==2) and align or {0,0}
	hidden=(hidden==nil) and false or hidden

	--Create the label
	local label=_G[name] or WM:CreateControl(name, parent, CT_LABEL)

	if dims then label:SetDimensions(dims[1], dims[2]) end
	label:ClearAnchors()
	label:SetAnchor(anchor[1], anchor[2], anchor[3], anchor[4], anchor[5])
	label:SetFont(font)
	label:SetColor(unpack(color))
	label:SetHorizontalAlignment(align[1])
	label:SetVerticalAlignment(align[2])
	label:SetText(text)
	label:SetHidden(hidden)

	IE_CONTROLS.SetTooltip(label, tooltip)

	label:SetDrawTier(2)

	return label
end


