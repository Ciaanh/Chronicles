local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles
Chronicles.Custom = {}
Chronicles.Custom.DB = {}
Chronicles.Custom.Modules = {
	expansions = "expansions",
	origins = "origins",
	greatwars = "greatwars",
	worldofwarcraft = "worldofwarcraft",
	burningcrusade = "burningcrusade",
	lichking = "lichking",
	cataclysm = "cataclysm",
	mistsofpandaria = "mistsofpandaria",
	warlords = "warlords",
	legion = "legion",
	battleforazeroth = "battleforazeroth",
	shadowlands = "shadowlands",
	dragonflight = "dragonflight",
	future = "future",
	warwithin = "warwithin"
}
function Chronicles.Custom.DB:Init()
	Chronicles.Data:RegisterEventDB(Chronicles.Custom.Modules.expansions, ExpansionsEventsDB)
	Chronicles.Data:RegisterEventDB(Chronicles.Custom.Modules.origins, OriginsEventsDB)
	Chronicles.Data:RegisterEventDB(Chronicles.Custom.Modules.warwithin, WarwithinEventsDB)   
end