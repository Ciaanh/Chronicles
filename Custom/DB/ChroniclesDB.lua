local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles
Chronicles.Custom = {}
Chronicles.Custom.DB = {}
Chronicles.Custom.Modules = {
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
function Chronicles.Custom.DB:Init()
	Chronicles.Data:RegisterEventDB(Chronicles.Custom.Modules.expansions, ExpansionsEventsDB)

	Chronicles.Data:RegisterEventDB(Chronicles.Custom.Modules.origins, OriginsEventsDB)

	Chronicles.Data:RegisterEventDB(Chronicles.Custom.Modules.future, FutureEventsDB)
	Chronicles.Data:RegisterCharacterDB(Chronicles.Custom.Modules.future, FutureCharactersDB)

	Chronicles.Data:RegisterEventDB(Chronicles.Custom.Modules.warwithin, WarwithinEventsDB)
	Chronicles.Data:RegisterCharacterDB(Chronicles.Custom.Modules.warwithin, WarwithinCharactersDB)
   
end