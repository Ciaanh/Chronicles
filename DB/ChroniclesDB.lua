local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles
Chronicles.DB = {}
Chronicles.DB.Modules = {
	expansions = "Expansions",
	origins = "Origins",
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
	warwithin = "Warwithin"
}
function Chronicles.DB:Init()
	Chronicles.Data:RegisterEventDB(Chronicles.DB.Modules.expansions, ExpansionsEventsDB)

	Chronicles.Data:RegisterEventDB(Chronicles.DB.Modules.origins, OriginsEventsDB)

	Chronicles.Data:RegisterEventDB(Chronicles.DB.Modules.future, FutureEventsDB)
	Chronicles.Data:RegisterFactionDB(Chronicles.DB.Modules.future, FutureFactionsDB)
	Chronicles.Data:RegisterCharacterDB(Chronicles.DB.Modules.future, FutureCharactersDB)

	Chronicles.Data:RegisterEventDB(Chronicles.DB.Modules.warwithin, WarwithinEventsDB)
	Chronicles.Data:RegisterCharacterDB(Chronicles.DB.Modules.warwithin, WarwithinCharactersDB)
   
end