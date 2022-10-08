-- Relative require in same directory
-- Global, because I don't want to declare it in every. single. file.
function _Require_relative(PATH, file, up)
    up = up or 0
    local path, match
    path, _     = ( (PATH):gsub("\\",".") ):gsub("/",".")
    path, match = path:gsub("(.*)%..*$", "%1" )
    for i = 1, up do
        path, match = path:gsub("%.(%w+)$", '')
    end
	return require(table.concat({path, file}, "."))
end

local scandir = require( table.concat({..., 'scandir'},".") )

Libs = scandir('lib')
for _, filename in ipairs(Libs) do
    local ext = filename:match("^.+(%..+)$")
    local name = ext == '.lua' and filename:gsub('.lua', '') or filename
    Libs[name] = require( table.concat({..., 'lib',name},".") )
end

local Strike = require( table.concat({..., 'Strike'},".") )

return Strike