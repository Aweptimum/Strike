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
    --path = match == 0 and '.'..file or path
    print('path: '..table.concat({path, file}, "."))
	return require(table.concat({path, file}, "."))
end

local scandir = require( table.concat({..., 'fileloader'},".") )

Libs = scandir('lib')
for _, filename in ipairs(Libs) do
    local ext = filename:sub(filename:len()-3, filename:len())
    local name = ext == '.lua' and filename:sub(1,filename:len()-4) or filename
    print('lib name: '..name)
    Libs[name] = require( table.concat({..., 'lib',name},".") )
end

local Strike  = require( table.concat({..., 'Strike'},".") )


return Strike