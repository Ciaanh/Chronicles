local FOLDER_NAME, private = ...
local Chronicles = private.Core

Chronicles.Custom = {}
Chronicles.Custom.DB = {}
Chronicles.Custom.Modules = {
	mythos = "mythos",
	-- beforedarkportal = "beforedarkportal",
	-- threewars = "threewars",
	-- vanilla = "vanilla",
	-- burningcrusade = "burningcrusade",
	-- lichking = "lichking",
	-- cataclysm = "cataclysm",
	-- pandaria = "pandaria",
	-- warlords = "warlords",
	-- legion = "legion",
	-- battleforazeroth = "battleforazeroth",
	-- shadowlands = "shadowlands"
}

function Chronicles.Custom.DB:Init()
    Chronicles.DB:RegisterEventDB(Chronicles.Custom.Modules.mythos, MythosEventsDB)
    Chronicles.DB:RegisterFactionDB(Chronicles.Custom.Modules.mythos, MythosFactionsDB)
    Chronicles.DB:RegisterCharacterDB(Chronicles.Custom.Modules.mythos, MythosCharactersDB)

    -- self:RegisterEventDB(Chronicles.Custom.Modules.beforedarkportal, BeforeDarkPortalEventsDB)
    -- self:RegisterFactionDB(Chronicles.Custom.Modules.beforedarkportal, BeforeDarkPortalFactionsDB)
    -- self:RegisterCharacterDB(Chronicles.Custom.Modules.beforedarkportal, BeforeDarkPortalCharactersDB)

    -- self:RegisterEventDB(Chronicles.Custom.Modules.threewars, ThreeWarsEventsDB)
    -- self:RegisterFactionDB(Chronicles.Custom.Modules.threewars, ThreeWarsFactionsDB)
    -- self:RegisterCharacterDB(Chronicles.Custom.Modules.threewars, ThreeWarsCharactersDB)

    -- self:RegisterEventDB(Chronicles.Custom.Modules.vanilla, VanillaEventsDB)
    -- self:RegisterFactionDB(Chronicles.Custom.Modules.vanilla, VanillaFactionsDB)
    -- self:RegisterCharacterDB(Chronicles.Custom.Modules.vanilla, VanillaCharactersDB)

    -- self:RegisterEventDB(Chronicles.Custom.Modules.burningcrusade, BCEventsDB)
    -- self:RegisterFactionDB(Chronicles.Custom.Modules.burningcrusade, BCFactionsDB)
    -- self:RegisterCharacterDB(Chronicles.Custom.Modules.burningcrusade, BCCharactersDB)

    -- self:RegisterEventDB(Chronicles.Custom.Modules.lichking, WOTLKEventsDB)
    -- self:RegisterFactionDB(Chronicles.Custom.Modules.lichking, WOTLKFactionsDB)
    -- self:RegisterCharacterDB(Chronicles.Custom.Modules.lichking, WOTLKCharactersDB)

    -- self:RegisterEventDB(Chronicles.Custom.Modules.cataclysm, CataclysmEventsDB)
    -- self:RegisterFactionDB(Chronicles.Custom.Modules.cataclysm, CataclysmFactionsDB)
    -- self:RegisterCharacterDB(Chronicles.Custom.Modules.cataclysm, CataclysmCharactersDB)

    -- self:RegisterEventDB(Chronicles.Custom.Modules.pandaria, MOPEventsDB)
    -- self:RegisterFactionDB(Chronicles.Custom.Modules.pandaria, MOPFactionsDB)
    -- self:RegisterCharacterDB(Chronicles.Custom.Modules.pandaria, MOPCharactersDB)

    -- self:RegisterEventDB(Chronicles.Custom.Modules.warlords, WODEventsDB)
    -- self:RegisterFactionDB(Chronicles.Custom.Modules.warlords, WODFactionsDB)
    -- self:RegisterCharacterDB(Chronicles.Custom.Modules.warlords, WODCharactersDB)

    -- self:RegisterEventDB(Chronicles.Custom.Modules.legion, LegionEventsDB)
    -- self:RegisterFactionDB(Chronicles.Custom.Modules.legion, LegionFactionsDB)
    -- self:RegisterCharacterDB(Chronicles.Custom.Modules.legion, LegionCharactersDB)

    -- self:RegisterEventDB(Chronicles.Custom.Modules.battleforazeroth, BFAEventsDB)
    -- self:RegisterFactionDB(Chronicles.Custom.Modules.battleforazeroth, BFAFactionsDB)
    -- self:RegisterCharacterDB(Chronicles.Custom.Modules.battleforazeroth, BFACharactersDB)

    -- self:RegisterEventDB(Chronicles.Custom.Modules.shadowlands, ShadowlandsEventsDB)
    -- self:RegisterFactionDB(Chronicles.Custom.Modules.shadowlands, ShadowlandsFactionsDB)
    -- self:RegisterCharacterDB(Chronicles.Custom.Modules.shadowlands, ShadowlandsCharactersDB)
end
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
