-- Single-line comment: Variable declaration and basic types
local version = 5.4
local projectName = "Lua Compiler" -- String declaration

-- Multi-line comment
--[[
  This function demonstrates parameters, 
  relational expressions, and a conditional statement.
]]
function checkLevel(score)
    local threshold = 100
    if score >= threshold then
        print("Level Up!")
    else
        print("Keep training.")
    end
end

-- A loop statement (while) with arithmetic and logical expressions
local counter = 1
while counter <= 5 and true do
    local result = (counter * 2) + 10 / 2  -- Multiple precedence levels
    print("Iteration: " .. counter .. " Result: " .. result)
    counter = counter + 1
end

local arr = {3, 6, 8}
for _, v in ipairs(arr) do
    print(v)
end

for i=1,5 do 
    print(i)
end

local t = true
local f = false
local n = nil

-- Object-Oriented Programming (Basic Table-based approach)
local Player = {hp = 100, mp = 50}

function Player:takeDamage(amount)
    self.hp = self.hp - amount
    if self.hp < 0 then self.hp = 0 end
end

-- Usage
Player:takeDamage(20)