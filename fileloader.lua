local function get_script_path()
	local info = debug.getinfo(1,'S');
	local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
	--print('script path is: '..script_path)
	return script_path
end

-- Lua implementation of PHP scandir function
local function scandir(directory)
    directory = get_script_path() .. directory .. "/"
    local i, t, popen = 0, {}, io.popen
    for filename in popen('dir "'..directory..'" /b'):lines() do
        --print(filename)
        i = i + 1
        t[i] = filename
    end
    return t
end

return scandir