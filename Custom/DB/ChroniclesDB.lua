local FOLDER_NAME, private = ...
local Chronicles = private.Core
Chronicles.Custom = {}
Chronicles.Custom.DB = {}
Chronicles.Custom.Modules = {
	expansions = "expansions",
	origins = "origins"
}
function Chronicles.Custom.DB:Init()
	Chronicles.DB:RegisterEventDB(Chronicles.Custom.Modules.expansions, ExpansionsEventsDB)
	Chronicles.DB:RegisterEventDB(Chronicles.Custom.Modules.origins, OriginsEventsDB)   
end