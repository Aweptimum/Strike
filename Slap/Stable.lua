-- Create API table
local Stable = {}

-- Initialize table stack
Stable.stack = {}

-- Alias table.insert/table.remove to push/pop
local push, pop = table.insert, table.remove

-- clear tables for re-use once they serve their purpose
-- Iterate through keys and set all to nil
function Stable:clean_table(table)
    for key, _ in pairs(table) do
        table[key] = nil
    end
end

-- Add n tables to the stack
-- This can be useful for allocating tables ahead of time
-- Front-loading table creation means less overhead incurred in the future (if done right)
function Stable:pad_stack(n)
    n = n <= 50 and n or 50
    for i = 1, n do
        push( self.stack, {} )
    end
end

-- Clean a table and push it to the stack
-- TODO: Needs to handle nested tables; invoke clean_table() when a table only contains values
function Stable:eat_table(table)
    -- Check for nested tables
    for key, value in pairs(table) do
        if type(value) == "table" then
            self:eat_table(table)
        end
    end
	self:clean_table(table)
	push( self.stack, table )
end

-- Pop a table from the stack or return a new one if the stack is empty
function Stable:fetch_table()
	if #self.stack == 0 then
		self:eat_table({})
	end
	return pop( self.stack )
end

-- Pop n tables from the stack
function Stable:fetch_table_n(n)
    n = n or 1
    if n >= 1 then
        return self:fetch_table(), self:fetch_table_n(n-1)
    end
end

-- Test nested_eat_table
local tbl = {
    a = { a = {} },
    b = { b = {} },
    c = { c = {} }
}
Stable:eat_table( tbl )

return Stable