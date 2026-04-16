local version = 5.4
local limit = 10
local flag = true

--[[
  Valid program for Phase 2:
  declaration, assignment, expression, if, while
]]
local x = 2
local y = 3

x = x + y * 4

if x > 5 and flag then
    y = x - 1
else
    y = x + 1
end

while y < limit do
    y = y + 2
end
