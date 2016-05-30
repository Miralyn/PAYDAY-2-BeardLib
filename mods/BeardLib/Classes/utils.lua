function table.merge(og_table, new_table)
	for i, data in pairs(new_table) do
		i = type(data) == "table" and data.index or i
		if type(data) == "table" and og_table[i] then
			og_table[i] = table.merge(og_table[i], data)
		else
			og_table[i] = data
		end
	end
	return og_table
end

function table.add(t, items)
	for i, sub_item in ipairs(items) do
		if t[i] then
			table.insert(t, sub_item)
		else
			t[i] = sub_item
		end
	end
end

function table.search(tbl, search_term)
    local search_terms = {search_term}

    if string.find(search_term, "/") then
        search_terms = string.split(search_term, "/")
    end

	local index
    for _, term in pairs(search_terms) do
        local term_parts = {term}
        if string.find(term, ";") then
            term_parts = string.split(term, ";")
        end
        local search_keys = {
            params = {}
        }
        for _, term in pairs(term_parts) do
            if string.find(term, "=") then
                local term_split = string.split(term, "=")
                search_keys.params[term_split[1]] = loadstring("return " .. term_split[2])()

				if not search_keys.params[term_split[1]] then
					BeardLib:log(string.format("[ERROR] An error occured while trying to parse the value %s", term_split[2]))
				end
            elseif not search_keys._meta then
                search_keys._meta = term
            end
        end

		local found_tbl = false
        for i, sub in ipairs(tbl) do
            if type(sub) == "table" then
                local valid = true
                if search_keys._meta and sub._meta ~= search_keys._meta then
                    valid = false
                end

                for k, v in pairs(search_keys.params) do
                    if sub[k] == nil or (sub[k] and sub[k] ~= v) then
                        valid = false
                        break
                    end
                end

                if valid then
                    if i == 1 then
                        if tbl[sub._meta] then
                            tbl[sub._meta] = sub
                        end
                    end

                    tbl = sub
					found_tbl = true
					index = i
                    break
                end
            end
        end
		if not found_tbl then
			return nil
		end
    end
	return index, tbl
end

function table.custom_insert(tbl, add_tbl, pos_phrase)
	if not pos_phrase then
		table.insert(tbl, add_tbl)
		return
	end

	if tonumber(pos_phrase) ~= nil then
		table.insert(tbl, pos_phrase, add_tbl)
	else
		local phrase_split = string.split(pos_phrase, ":")
		local i, _ = table.search(tbl, phrase_split[2])

		if not i then
			BeardLib:log(string.format("[ERROR] Could not find table for relative placement. %s", pos_phrase))
			table.insert(tbl, add_tbl)
		else
			i = phrase_split[1] == "after" and i + 1 or i
			table.insert(tbl, i, add_tbl)
		end
	end
end

local special_params = {
    "search",
	"index"
}

function table.script_merge(base_tbl, new_tbl)
    for i, sub in pairs(new_tbl) do
        if type(sub) == "table" then
            if tonumber(i) ~= nil then
                if sub.search then
                    local index, found_tbl = table.search(base_tbl, sub.search)
                    if found_tbl then
                        table.script_merge(found_tbl, sub)
                    end
                else
                    table.custom_insert(base_tbl, sub, sub.index)
					if not base_tbl[sub._meta] then
						base_tbl[sub._meta] = sub
					end
					for _, param in pairs(special_params) do
						sub[param] = nil
					end
                end
            --[[else
                if not base_tbl[i] then
                    base_tbl[i] = sub
                end]]--
            end
        elseif not table.contains(special_params, i) then
            base_tbl[i] = sub
        end
    end
end


function string.key(str)
    local ids = Idstring(str)
    local key = ids:key()
    return tostring(key)
end

function math.EulerToQuarternion(x, y, z)
    local quad = {
        math.cos(z / 2) * math.cos(y / 2) * math.cos(x / 2) + math.sin(z / 2) * math.sin(y / 2) * math.sin(x / 2),
        math.sin(z / 2) * math.cos(y / 2) * math.cos(x / 2) - math.cos(z / 2) * math.sin(y / 2) * math.sin(x / 2),
        math.cos(z / 2) * math.sin(y / 2) * math.cos(x / 2) + math.sin(z / 2) * math.cos(y / 2) * math.sin(x / 2),
        math.cos(z / 2) * math.cos(y / 2) * math.sin(x / 2) - math.sin(z / 2) * math.sin(y / 2) * math.cos(x / 2),
    }
    return quad
end

-- Doesn't produce the same output as the game. Any help on fixing that would be appreciated.
function math.QuaternionToEuler(x, y, z, w)
    local sqw = w * w
    local sqx = x * x
    local sqy = y * y
    local sqz = z * z

    local normal = math.sqrt(sqw + sqx + sqy + sqz)
    local pole_result = (x * z) + (y * w)

    if (pole_result > (0.5 * normal)) then --singularity at north pole
        local ry = math.pi/2 --heading/yaw?
        local rz = 0 --attitude/roll?
        local rx = 2 * math.atan2(x, w) --bank/pitch?
        return Rotation(rx, ry, rz)
    end

    if (pole_result < (-0.5 * normal)) then --singularity at south pole
        local ry = -math.pi/2
        local rz = 0
        local rx = -2 * math.atan2(x, w)
        return Rotation(rx, ry, rz)
    end

    local r11 = 2*(x*y + w*z)
    local r12 = sqw + sqx - sqy - sqz
    local r21 = -2*(x*z - w*y)
    local r31 = 2*(y*z + w*x)
    local r32 = sqw - sqx - sqy + sqz

    local rx = math.atan2( r31, r32 )
    local ry = math.asin ( r21 )
    local rz = math.atan2( r11, r12 )

    return Rotation(rx, ry, rz)



    --[[local yaw = math.atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z))
    local pitch = math.asin(2 * (w * y - z * x))
    local roll = math.atan2(2 * (w * x + y * z), 1 - 2 * (x * x + y * y))

    return Rotation(yaw, pitch, roll)]]--
end

BeardLib.Utils = {}

function BeardLib.Utils:StringToTable(global_tbl_name)
    local global_tbl
    if string.find(global_tbl_name, "%.") then
        local global_tbl_split = string.split(global_tbl_name, "[.]")
        global_tbl = _G
        for _, str in pairs(global_tbl_split) do
            global_tbl = rawget(global_tbl, str)
            if not global_tbl then
                BeardLib:log("[ERROR] Key " .. str .. " does not exist in the current global table.")
                return nil
            end
        end
    else
        global_tbl = rawget(_G, global_tbl_name)
        if not global_tbl then
            BeardLib:log("[ERROR] Key " .. global_tbl_name .. " does not exist in the global table.")
            return nil
        end
    end

    return global_tbl
end

function BeardLib.Utils:RemoveAllSubTables(tbl)
    for i, sub in pairs(tbl) do
        if type(sub) == "table" then
            tbl[i] = nil
        end
    end
    return tbl
end

function BeardLib.Utils:RemoveAllNumberIndexes(tbl)
	if not tbl then return nil end

    if type(tbl) ~= "table" then
        return tbl
    end

    for i, sub in pairs(tbl) do
        if tonumber(i) ~= nil then
            tbl[i] = nil
        elseif type(sub) == "table" then
            tbl[i] = self:RemoveAllNumberIndexes(sub)
        end
    end

    return tbl
end

function BeardLib.Utils:RemoveNonNumberIndexes(tbl)
	if not tbl then return nil end

    if type(tbl) ~= "table" then
        return tbl
    end

    for i, _ in pairs(tbl) do
        if tonumber(i) == nil then
            tbl[i] = nil
        end
    end

    return tbl
end

local encode_chars = {
	["\t"] = "%09",
	["\n"] = "%0A",
	["\r"] = "%0D",
	[" "] = "+",
	["!"] = "%21",
	['"'] = "%22",
	[":"] = "%3A",
	["{"] = "%7B",
	["}"] = "%7D",
	["["] = "%5B",
	["]"] = "%5D",
	[","] = "%2C"
}
function BeardLib.Utils:UrlEncode(str)
	if not str then
		return ""
	end

	return string.gsub(str, ".", encode_chars)
end

BeardLib.Utils.Math = {}

function BeardLib.Utils.Math:Round(val, dp)
	local mult = 10^(dp or 0)
	return math.floor(val * mult + 0.5) / mult
end
