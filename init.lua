-- Relative require in same directory
-- Global, because I don't want to declare it in every. single. file.
function _Require_relative(PATH, file)
    local path, match
    path, _     = ( (PATH):gsub("\\",".") ):gsub("/",".")
    path, match = path:gsub("(.*)%..*$", "%1" )
    --path = match == 0 and '.'..file or path
    print('path: '..table.concat({path, file}, "."))
	return require(table.concat({path, file}, "."))
end

local Strike = _Require_relative(...,'Strike')

return Strike