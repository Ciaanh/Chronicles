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
	Chronicles.Data:RegisterFactionDB(Chronicles.Custom.Modules.expansions, ExpansionsFactionsDB)
	Chronicles.Data:RegisterCharacterDB(Chronicles.Custom.Modules.expansions, ExpansionsCharactersDB)
	Chronicles.Data:RegisterEventDB(Chronicles.Custom.Modules.origins, OriginsEventsDB)
	Chronicles.Data:RegisterFactionDB(Chronicles.Custom.Modules.origins, OriginsFactionsDB)
	Chronicles.Data:RegisterCharacterDB(Chronicles.Custom.Modules.origins, OriginsCharactersDB)
	Chronicles.Data:RegisterEventDB(Chronicles.Custom.Modules.greatwars, GreatwarsEventsDB)
	Chronicles.Data:RegisterFactionDB(Chronicles.Custom.Modules.greatwars, GreatwarsFactionsDB)
	Chronicles.Data:RegisterCharacterDB(Chronicles.Custom.Modules.greatwars, GreatwarsCharactersDB)
	Chronicles.Data:RegisterEventDB(Chronicles.Custom.Modules.worldofwarcraft, WorldofwarcraftEventsDB)
	Chronicles.Data:RegisterFactionDB(Chronicles.Custom.Modules.worldofwarcraft, WorldofwarcraftFactionsDB)
	Chronicles.Data:RegisterCharacterDB(Chronicles.Custom.Modules.worldofwarcraft, WorldofwarcraftCharactersDB)
	Chronicles.Data:RegisterEventDB(Chronicles.Custom.Modules.burningcrusade, BurningcrusadeEventsDB)
	Chronicles.Data:RegisterFactionDB(Chronicles.Custom.Modules.burningcrusade, BurningcrusadeFactionsDB)
	Chronicles.Data:RegisterCharacterDB(Chronicles.Custom.Modules.burningcrusade, BurningcrusadeCharactersDB)
	Chronicles.Data:RegisterEventDB(Chronicles.Custom.Modules.lichking, LichkingEventsDB)
	Chronicles.Data:RegisterFactionDB(Chronicles.Custom.Modules.lichking, LichkingFactionsDB)
	Chronicles.Data:RegisterCharacterDB(Chronicles.Custom.Modules.lichking, LichkingCharactersDB)
	Chronicles.Data:RegisterEventDB(Chronicles.Custom.Modules.cataclysm, CataclysmEventsDB)
	Chronicles.Data:RegisterFactionDB(Chronicles.Custom.Modules.cataclysm, CataclysmFactionsDB)
	Chronicles.Data:RegisterCharacterDB(Chronicles.Custom.Modules.cataclysm, CataclysmCharactersDB)
	Chronicles.Data:RegisterEventDB(Chronicles.Custom.Modules.mistsofpandaria, MistsofpandariaEventsDB)
	Chronicles.Data:RegisterFactionDB(Chronicles.Custom.Modules.mistsofpandaria, MistsofpandariaFactionsDB)
	Chronicles.Data:RegisterCharacterDB(Chronicles.Custom.Modules.mistsofpandaria, MistsofpandariaCharactersDB)
	Chronicles.Data:RegisterEventDB(Chronicles.Custom.Modules.warlords, WarlordsEventsDB)
	Chronicles.Data:RegisterFactionDB(Chronicles.Custom.Modules.warlords, WarlordsFactionsDB)
	Chronicles.Data:RegisterCharacterDB(Chronicles.Custom.Modules.warlords, WarlordsCharactersDB)
	Chronicles.Data:RegisterEventDB(Chronicles.Custom.Modules.legion, LegionEventsDB)
	Chronicles.Data:RegisterFactionDB(Chronicles.Custom.Modules.legion, LegionFactionsDB)
	Chronicles.Data:RegisterCharacterDB(Chronicles.Custom.Modules.legion, LegionCharactersDB)
	Chronicles.Data:RegisterEventDB(Chronicles.Custom.Modules.battleforazeroth, BattleforazerothEventsDB)
	Chronicles.Data:RegisterFactionDB(Chronicles.Custom.Modules.battleforazeroth, BattleforazerothFactionsDB)
	Chronicles.Data:RegisterCharacterDB(Chronicles.Custom.Modules.battleforazeroth, BattleforazerothCharactersDB)
	Chronicles.Data:RegisterEventDB(Chronicles.Custom.Modules.shadowlands, ShadowlandsEventsDB)
	Chronicles.Data:RegisterFactionDB(Chronicles.Custom.Modules.shadowlands, ShadowlandsFactionsDB)
	Chronicles.Data:RegisterCharacterDB(Chronicles.Custom.Modules.shadowlands, ShadowlandsCharactersDB)
	Chronicles.Data:RegisterEventDB(Chronicles.Custom.Modules.dragonflight, DragonflightEventsDB)
	Chronicles.Data:RegisterFactionDB(Chronicles.Custom.Modules.dragonflight, DragonflightFactionsDB)
	Chronicles.Data:RegisterCharacterDB(Chronicles.Custom.Modules.dragonflight, DragonflightCharactersDB)
	Chronicles.Data:RegisterEventDB(Chronicles.Custom.Modules.future, FutureEventsDB)
	Chronicles.Data:RegisterFactionDB(Chronicles.Custom.Modules.future, FutureFactionsDB)
	Chronicles.Data:RegisterCharacterDB(Chronicles.Custom.Modules.future, FutureCharactersDB)
	Chronicles.Data:RegisterEventDB(Chronicles.Custom.Modules.warwithin, WarwithinEventsDB)
	Chronicles.Data:RegisterFactionDB(Chronicles.Custom.Modules.warwithin, WarwithinFactionsDB)
	Chronicles.Data:RegisterCharacterDB(Chronicles.Custom.Modules.warwithin, WarwithinCharactersDB)   
end