local IE = InventoryExtensions

function IE.CallLater(name,ms,func,opt1,opt2)
	if ms then
		EVENT_MANAGER:RegisterForUpdate("CallLater_"..name, ms,
		function()
			EVENT_MANAGER:UnregisterForUpdate("CallLater_"..name)
			func(opt1,opt2)
		end)
	else
		EVENT_MANAGER:UnregisterForUpdate("CallLater_"..name)
	end
end

function IE.LogLater(obj)
	zo_callLater(function() d(obj) end, 200)
end

function IE.RegisterForControlShown()
	local num = GuiRoot:GetNumChildren()
	for i = 1, num, 1 do
	    local child = GuiRoot:GetChild(i)
	    if child then
	        local control = _G[child:GetName()]
	        if control then
	            ZO_PreHookHandler(_G[control:GetName()], 'OnEffectivelyShown', function() IE.LogLater(GetTimeStamp().." "..control:GetName().." shown") end)
	        end
	    end
	end
end