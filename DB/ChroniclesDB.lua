local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles
Chronicles.DB = {}
Chronicles.DB.Modules = {
	sample = "Sample",
	greatwars = "Greatwars",
	worldofwarcraft = "Worldofwarcraft",
	burningcrusade = "Burningcrusade",
	lichking = "Lichking",
	cataclysm = "Cataclysm",
	mistsofpandaria = "Mistsofpandaria",
	warlords = "Warlords",
	legion = "Legion",
	battleforazeroth = "Battleforazeroth",
	shadowlands = "Shadowlands",
	dragonflight = "Dragonflight",
	future = "Future",
	warwithin = "Warwithin",
	expansions = "Expansions"
}

function Chronicles.DB:Init()
	Chronicles.Data:RegisterEventDB(Chronicles.DB.Modules.sample, SampleEventsDB)

	Chronicles.Data:RegisterEventDB(Chronicles.DB.Modules.future, FutureEventsDB)
	Chronicles.Data:RegisterFactionDB(Chronicles.DB.Modules.future, FutureFactionsDB)
	Chronicles.Data:RegisterCharacterDB(Chronicles.DB.Modules.future, FutureCharactersDB)

	Chronicles.Data:RegisterEventDB(Chronicles.DB.Modules.warwithin, WarwithinEventsDB)
	Chronicles.Data:RegisterCharacterDB(Chronicles.DB.Modules.warwithin, WarwithinCharactersDB)

	Chronicles.Data:RegisterEventDB(Chronicles.DB.Modules.expansions, ExpansionsEventsDB)
end

-- Single-entity lookup methods that delegate to Chronicles.Data
function Chronicles.DB:FindEventByIdAndCollection(eventId, collectionName)
	return Chronicles.Data:FindEventByIdAndCollection(eventId, collectionName)
end

function Chronicles.DB:FindCharacterByIdAndCollection(characterId, collectionName)
	return Chronicles.Data:FindCharacterByIdAndCollection(characterId, collectionName)
end

function Chronicles.DB:FindFactionByIdAndCollection(factionId, collectionName)
	return Chronicles.Data:FindFactionByIdAndCollection(factionId, collectionName)
end