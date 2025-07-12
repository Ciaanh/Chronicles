local FOLDER_NAME, private = ...

ChroniclesPluginData = ChroniclesPluginData or {}

function ChroniclesPluginData.Register()
	local DataRegistry
	if (private.Chronicles) then
		DataRegistry = Chronicles.Data
	else
		if _G.Chronicles and _G.Chronicles.Data then
			DataRegistry = _G.Chronicles.Data
		else
			-- print("|cffff0000Error:|r Chronicles DataRegistry not found!")
			return
		end
	end

	if SampleEventsDB then DataRegistry:RegisterEventDB("Sample", SampleEventsDB) end
	if SampleFactionsDB then DataRegistry:RegisterFactionDB("Sample", SampleFactionsDB) end
	if SampleCharactersDB then DataRegistry:RegisterCharacterDB("Sample", SampleCharactersDB) end


	-- print("|cff00ff00Chronicles:|r Sample data registered successfully")
end