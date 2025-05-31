local FOLDER_NAME, private = ...

private.Core.Utils = private.Core.Utils or {}
private.Core.Utils.TableUtils = {}

local TableUtils = private.Core.Utils.TableUtils

--[[
    Create a set from a list (array to hash table conversion)
    @param list [table] Array to convert to set
    @return [table] Set (hash table with values as keys)
]]
function TableUtils.Set(list)
    local set = {}
    for _, l in ipairs(list) do
        set[l] = true
    end
    return set
end

--[[
    Get the length of a table (including hash tables)
    @param T [table] Table to measure
    @return [number] Number of elements in the table
]]
function TableUtils.Length(T)
    if (T == nil) then
        return 0
    end

    local count = 0
    for _ in pairs(T) do
        count = count + 1
    end
    return count
end

--[[
    Deep copy a table with all nested tables
    @param tableToCopy [table] Table to copy
    @return [table] Deep copy of the table
]]
function TableUtils.DeepCopy(tableToCopy)
    if (tableToCopy == nil) then
        return {}
    end

    local orig_type = type(tableToCopy)
    local copy
    if orig_type == "table" then
        copy = {}
        for orig_key, orig_value in pairs(tableToCopy) do
            local orig_value_type = type(orig_value)
            if (orig_value_type == "table") then
                copy[orig_key] = TableUtils.DeepCopy(orig_value)
            else
                copy[orig_key] = orig_value
            end
        end
    else -- number, string, boolean, etc
        copy = tableToCopy
    end
    return copy
end

--[[
    Check if a table contains a specific value
    @param table [table] Table to search
    @param value [any] Value to find
    @return [boolean] True if value is found
]]
function TableUtils.Contains(table, value)
    if table == nil then
        return false
    end

    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

--[[
    Merge two tables, with values from second table taking precedence
    @param table1 [table] First table
    @param table2 [table] Second table (takes precedence)
    @return [table] Merged table
]]
function TableUtils.Merge(table1, table2)
    local result = TableUtils.DeepCopy(table1)

    if table2 == nil then
        return result
    end

    for key, value in pairs(table2) do
        if type(value) == "table" and type(result[key]) == "table" then
            result[key] = TableUtils.Merge(result[key], value)
        else
            result[key] = value
        end
    end

    return result
end

--[[
    Filter a table based on a predicate function
    @param table [table] Table to filter
    @param predicate [function] Function that returns true for items to keep
    @return [table] Filtered table
]]
function TableUtils.Filter(table, predicate)
    local result = {}

    if table == nil or predicate == nil then
        return result
    end

    for key, value in pairs(table) do
        if predicate(value, key) then
            result[key] = value
        end
    end

    return result
end

--[[
    Map a table to a new table using a transformation function
    @param table [table] Table to map
    @param mapper [function] Function to transform each value
    @return [table] Mapped table
]]
function TableUtils.Map(table, mapper)
    local result = {}

    if table == nil or mapper == nil then
        return result
    end

    for key, value in pairs(table) do
        result[key] = mapper(value, key)
    end

    return result
end

-- Export utility functions globally for backwards compatibility
_G.Set = TableUtils.Set
_G.tablelength = TableUtils.Length
_G.copyTable = TableUtils.DeepCopy
_G.TableUtils = TableUtils
