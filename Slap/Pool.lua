-- Create table pool within name-space (we're gonna need it for the triangulation functions)
local Pool = {}

-- table stack is within pool
Pool.stack = {}

-- Define Push/pop
local push, pop = table.insert, table.remove

-- clear re-usable tables once they serve their purpose
-- Iterate through keys and set all to nil
function Pool:clean_table(table)
    for key, _ in pairs(table) do
        table[key] = nil
    end
end

-- Add n tables to the stack
-- This can be useful for allocating tables ahead of time
-- Front-loading table creation means less overhead incurred in the future (if done right)
function Pool:pad_stack(n)
    n = n <= 50 and n or 50
    for i = 1, n do
        push( self.stack, {} )
    end
end

-- Clear a table and append it to the pool
function Pool:eat_table(table)
	self:clean_table(table)
	push( self.stack, table )
end

-- Fetch an empty table from the top of the pool's stack
function Pool:fetch_table()
	if #self.stack == 0 then
		self:eat_table({})
	end
	return pop( self.stack )
end

-- Fetch an empty table from the top of the pool's stack
function Pool:fetch_table_n(n)
    n = n or 1
    if n >= 1 then
        return self:fetch_table(), self:fetch_table_n(n-1)
    end
end

return Pool