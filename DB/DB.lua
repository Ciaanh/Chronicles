local FOLDER_NAME, private = ...

function private.registerInternalDBs()
	local Data = private.Chronicles and private.Chronicles.Data
	if not Data then
		return
	end

	if ExpansionsEventsDB then Data:RegisterEventDB("Expansions", ExpansionsEventsDB) end

	if OriginsEventsDB then Data:RegisterEventDB("Origins", OriginsEventsDB) end

	if GreatwarsEventsDB then Data:RegisterEventDB("Greatwars", GreatwarsEventsDB) end
	if GreatwarsFactionsDB then Data:RegisterFactionDB("Greatwars", GreatwarsFactionsDB) end
	if GreatwarsCharactersDB then Data:RegisterCharacterDB("Greatwars", GreatwarsCharactersDB) end

	if WorldofwarcraftEventsDB then Data:RegisterEventDB("Worldofwarcraft", WorldofwarcraftEventsDB) end
	if WorldofwarcraftFactionsDB then Data:RegisterFactionDB("Worldofwarcraft", WorldofwarcraftFactionsDB) end
	if WorldofwarcraftCharactersDB then Data:RegisterCharacterDB("Worldofwarcraft", WorldofwarcraftCharactersDB) end

	if BurningcrusadeEventsDB then Data:RegisterEventDB("Burningcrusade", BurningcrusadeEventsDB) end
	if BurningcrusadeFactionsDB then Data:RegisterFactionDB("Burningcrusade", BurningcrusadeFactionsDB) end
	if BurningcrusadeCharactersDB then Data:RegisterCharacterDB("Burningcrusade", BurningcrusadeCharactersDB) end

	if LichkingEventsDB then Data:RegisterEventDB("Lichking", LichkingEventsDB) end
	if LichkingFactionsDB then Data:RegisterFactionDB("Lichking", LichkingFactionsDB) end
	if LichkingCharactersDB then Data:RegisterCharacterDB("Lichking", LichkingCharactersDB) end

	if CataclysmEventsDB then Data:RegisterEventDB("Cataclysm", CataclysmEventsDB) end
	if CataclysmFactionsDB then Data:RegisterFactionDB("Cataclysm", CataclysmFactionsDB) end
	if CataclysmCharactersDB then Data:RegisterCharacterDB("Cataclysm", CataclysmCharactersDB) end

	if MistsofpandariaEventsDB then Data:RegisterEventDB("Mistsofpandaria", MistsofpandariaEventsDB) end
	if MistsofpandariaFactionsDB then Data:RegisterFactionDB("Mistsofpandaria", MistsofpandariaFactionsDB) end
	if MistsofpandariaCharactersDB then Data:RegisterCharacterDB("Mistsofpandaria", MistsofpandariaCharactersDB) end

	if WarlordsEventsDB then Data:RegisterEventDB("Warlords", WarlordsEventsDB) end
	if WarlordsFactionsDB then Data:RegisterFactionDB("Warlords", WarlordsFactionsDB) end
	if WarlordsCharactersDB then Data:RegisterCharacterDB("Warlords", WarlordsCharactersDB) end

	if LegionEventsDB then Data:RegisterEventDB("Legion", LegionEventsDB) end
	if LegionFactionsDB then Data:RegisterFactionDB("Legion", LegionFactionsDB) end
	if LegionCharactersDB then Data:RegisterCharacterDB("Legion", LegionCharactersDB) end

	if BattleforazerothEventsDB then Data:RegisterEventDB("Battleforazeroth", BattleforazerothEventsDB) end
	if BattleforazerothFactionsDB then Data:RegisterFactionDB("Battleforazeroth", BattleforazerothFactionsDB) end
	if BattleforazerothCharactersDB then Data:RegisterCharacterDB("Battleforazeroth", BattleforazerothCharactersDB) end

	if ShadowlandsEventsDB then Data:RegisterEventDB("Shadowlands", ShadowlandsEventsDB) end
	if ShadowlandsFactionsDB then Data:RegisterFactionDB("Shadowlands", ShadowlandsFactionsDB) end
	if ShadowlandsCharactersDB then Data:RegisterCharacterDB("Shadowlands", ShadowlandsCharactersDB) end

	if DragonflightEventsDB then Data:RegisterEventDB("Dragonflight", DragonflightEventsDB) end
	if DragonflightFactionsDB then Data:RegisterFactionDB("Dragonflight", DragonflightFactionsDB) end
	if DragonflightCharactersDB then Data:RegisterCharacterDB("Dragonflight", DragonflightCharactersDB) end

	if FutureEventsDB then Data:RegisterEventDB("Future", FutureEventsDB) end
	if FutureFactionsDB then Data:RegisterFactionDB("Future", FutureFactionsDB) end
	if FutureCharactersDB then Data:RegisterCharacterDB("Future", FutureCharactersDB) end

	if WarwithinEventsDB then Data:RegisterEventDB("Warwithin", WarwithinEventsDB) end
	if WarwithinFactionsDB then Data:RegisterFactionDB("Warwithin", WarwithinFactionsDB) end
	if WarwithinCharactersDB then Data:RegisterCharacterDB("Warwithin", WarwithinCharactersDB) end
end
