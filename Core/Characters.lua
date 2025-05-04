local FOLDER_NAME, private = ...

private.Core.Characters = {}


--[[

id = ${character._id},
name = Locale["${getLocaleKey(character.label)}"],
biography = Locale["${getLocaleKey(character.biography)}"],
timeline = ${character.timeline},
factions = {${character.factions.map((fac) => fac._id).join(", ")}}

--]]


--  Character
--  id = [integer]					-- Id of the event
-- 	name = [string]				    --
-- 	description = { [string] }		-- descriptions
-- 	chapters = { [chapter] }		--
-- 	yearStart = [integer]			--
-- 	yearEnd = [integer]				--
-- 	eventType = [integer]			--
-- 	timeline = [integer]			-- id of the timeline
-- 	order = [integer]				--
-- 	characters = { [character] }	--
-- 	factions = { [faction] }		--
--  author = [string]				-- Author of the event

--  Chapter
--  header = [integer]				-- Title of the chapter
-- 	pages = { [string] }			-- Content of the chapter, either text or HTML

--[[
    Transform the character into a book
    @param character [character]
]]
function private.Core.Characters.TransformCharacterToBook(character)
    if(character == nil) then
        return nil
    end

    local data = {}

	local title = {
		header = {
			templateKey = private.constants.templateKeys.EVENT_TITLE,
			text = event.label,
			yearStart = event.yearStart,
			yearEnd = event.yearEnd
		},
		elements = {}
	}



    return character
end
