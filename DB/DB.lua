local FOLDER_NAME, private = ...

function private.registerInternalDBs()
	local Data = private.Chronicles and private.Chronicles.Data
	if not Data then
		return
	end

	local DB = private.DB or {}

	if DB.ExpansionsEventsDB then Data:RegisterEventDB("Expansions", DB.ExpansionsEventsDB) end

	if DB.OriginsEventsDB then Data:RegisterEventDB("Origins", DB.OriginsEventsDB) end

	if DB.GreatwarsEventsDB then Data:RegisterEventDB("Greatwars", DB.GreatwarsEventsDB) end
	if DB.GreatwarsFactionsDB then Data:RegisterFactionDB("Greatwars", DB.GreatwarsFactionsDB) end
	if DB.GreatwarsCharactersDB then Data:RegisterCharacterDB("Greatwars", DB.GreatwarsCharactersDB) end

	if DB.WorldofwarcraftEventsDB then Data:RegisterEventDB("Worldofwarcraft", DB.WorldofwarcraftEventsDB) end
	if DB.WorldofwarcraftFactionsDB then Data:RegisterFactionDB("Worldofwarcraft", DB.WorldofwarcraftFactionsDB) end
	if DB.WorldofwarcraftCharactersDB then Data:RegisterCharacterDB("Worldofwarcraft", DB.WorldofwarcraftCharactersDB) end

	if DB.BurningcrusadeEventsDB then Data:RegisterEventDB("Burningcrusade", DB.BurningcrusadeEventsDB) end
	if DB.BurningcrusadeFactionsDB then Data:RegisterFactionDB("Burningcrusade", DB.BurningcrusadeFactionsDB) end
	if DB.BurningcrusadeCharactersDB then Data:RegisterCharacterDB("Burningcrusade", DB.BurningcrusadeCharactersDB) end

	if DB.LichkingEventsDB then Data:RegisterEventDB("Lichking", DB.LichkingEventsDB) end
	if DB.LichkingFactionsDB then Data:RegisterFactionDB("Lichking", DB.LichkingFactionsDB) end
	if DB.LichkingCharactersDB then Data:RegisterCharacterDB("Lichking", DB.LichkingCharactersDB) end

	if DB.CataclysmEventsDB then Data:RegisterEventDB("Cataclysm", DB.CataclysmEventsDB) end
	if DB.CataclysmFactionsDB then Data:RegisterFactionDB("Cataclysm", DB.CataclysmFactionsDB) end
	if DB.CataclysmCharactersDB then Data:RegisterCharacterDB("Cataclysm", DB.CataclysmCharactersDB) end

	if DB.MistsofpandariaEventsDB then Data:RegisterEventDB("Mistsofpandaria", DB.MistsofpandariaEventsDB) end
	if DB.MistsofpandariaFactionsDB then Data:RegisterFactionDB("Mistsofpandaria", DB.MistsofpandariaFactionsDB) end
	if DB.MistsofpandariaCharactersDB then Data:RegisterCharacterDB("Mistsofpandaria", DB.MistsofpandariaCharactersDB) end

	if DB.WarlordsEventsDB then Data:RegisterEventDB("Warlords", DB.WarlordsEventsDB) end
	if DB.WarlordsFactionsDB then Data:RegisterFactionDB("Warlords", DB.WarlordsFactionsDB) end
	if DB.WarlordsCharactersDB then Data:RegisterCharacterDB("Warlords", DB.WarlordsCharactersDB) end

	if DB.LegionEventsDB then Data:RegisterEventDB("Legion", DB.LegionEventsDB) end
	if DB.LegionFactionsDB then Data:RegisterFactionDB("Legion", DB.LegionFactionsDB) end
	if DB.LegionCharactersDB then Data:RegisterCharacterDB("Legion", DB.LegionCharactersDB) end

	if DB.BattleforazerothEventsDB then Data:RegisterEventDB("Battleforazeroth", DB.BattleforazerothEventsDB) end
	if DB.BattleforazerothFactionsDB then Data:RegisterFactionDB("Battleforazeroth", DB.BattleforazerothFactionsDB) end
	if DB.BattleforazerothCharactersDB then Data:RegisterCharacterDB("Battleforazeroth", DB.BattleforazerothCharactersDB) end

	if DB.ShadowlandsEventsDB then Data:RegisterEventDB("Shadowlands", DB.ShadowlandsEventsDB) end
	if DB.ShadowlandsFactionsDB then Data:RegisterFactionDB("Shadowlands", DB.ShadowlandsFactionsDB) end
	if DB.ShadowlandsCharactersDB then Data:RegisterCharacterDB("Shadowlands", DB.ShadowlandsCharactersDB) end

	if DB.DragonflightEventsDB then Data:RegisterEventDB("Dragonflight", DB.DragonflightEventsDB) end
	if DB.DragonflightFactionsDB then Data:RegisterFactionDB("Dragonflight", DB.DragonflightFactionsDB) end
	if DB.DragonflightCharactersDB then Data:RegisterCharacterDB("Dragonflight", DB.DragonflightCharactersDB) end

	if DB.FutureEventsDB then Data:RegisterEventDB("Future", DB.FutureEventsDB) end
	if DB.FutureFactionsDB then Data:RegisterFactionDB("Future", DB.FutureFactionsDB) end
	if DB.FutureCharactersDB then Data:RegisterCharacterDB("Future", DB.FutureCharactersDB) end

	if DB.WarwithinEventsDB then Data:RegisterEventDB("Warwithin", DB.WarwithinEventsDB) end
	if DB.WarwithinFactionsDB then Data:RegisterFactionDB("Warwithin", DB.WarwithinFactionsDB) end
	if DB.WarwithinCharactersDB then Data:RegisterCharacterDB("Warwithin", DB.WarwithinCharactersDB) end
end
