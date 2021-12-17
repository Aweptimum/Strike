-- [[---------------------]]         Table Utilities         [[---------------------]] --
local t = {}
-- Print table w/ formatting
function t.tprint (tbl, height, indent)
	if not tbl then return end
	height = height or 0
	indent = indent or 0
	for k, v in pairs(tbl) do
		height = height+1
		local formatting = string.rep("  ", indent) .. tostring(k) .. ": "
		if type(v) == "table" then
			print(formatting, indent*8, 16*height)
			t.tprint(v, height+1, indent+1)
		elseif type(v) == 'function' then
			print(formatting .. "function", indent*8, 16*height)
		elseif type(v) == 'boolean' then
			print(formatting .. tostring(v), indent*8, 16*height)
		else
			print(formatting .. v, indent*8, 16*height)
		end
	end
end

-- Shallow copy table (depth-of-1) into re-usable table
-- Modified from lua-users wiki (http://lua-users.org/wiki/CopyTable)
function t.shallow_copy(orig, copy)
	copy = copy or {}
	local orig_type, copy_type = type(orig), type(copy)
    if orig_type == 'table' and copy_type == 'table' then
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else
		return false -- not a table ye dummy
    end
    return copy
end

-- Recursively copy table
-- Taken from lua-users wiki
function t.deep_copy(o, seen)
	seen = seen or {}
	if o == nil then return nil end
	if seen[o] then return seen[o] end
		local no
		if type(o) == 'table' then
			no = {}
			seen[o] = no

			for k, v in next, o, nil do
				no[t.deep_copy(k, seen)] = t.deep_copy(v, seen)
			end
			setmetatable(no, t.deep_copy(getmetatable(o), seen))
		else -- number, string, boolean, etc
			no = o
		end
	return no
end

return t