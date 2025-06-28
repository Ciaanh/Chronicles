local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles
Chronicles.DB = {}
Chronicles.DB.Modules = {
	sample = "Sample"
}
function Chronicles.DB:Init()
	Chronicles.Data:RegisterEventDB(Chronicles.DB.Modules.sample, SampleEventsDB)
	Chronicles.Data:RegisterFactionDB(Chronicles.DB.Modules.sample, SampleFactionsDB)
	Chronicles.Data:RegisterCharacterDB(Chronicles.DB.Modules.sample, SampleCharactersDB)
   
end