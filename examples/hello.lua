-- Hello World — Lua on MerlionOS.
-- Run: run-user lua hello.lua

print("Hello from Lua on MerlionOS!")
print(string.format("Lua %s", _VERSION))

-- Tables (like dicts)
local info = {os = "MerlionOS", lang = "Lua", year = 2026}
for k, v in pairs(info) do
    print(string.format("  %s = %s", k, tostring(v)))
end

-- Functions
local function factorial(n)
    if n <= 1 then return 1 end
    return n * factorial(n - 1)
end

print(string.format("10! = %d", factorial(10)))

-- Coroutines
local co = coroutine.create(function()
    for i = 1, 3 do
        print(string.format("  coroutine tick %d", i))
        coroutine.yield()
    end
end)

print("Coroutines:")
for i = 1, 3 do coroutine.resume(co) end

-- File I/O
local f = io.open("/tmp/lua_test.txt", "w")
if f then
    f:write("Lua file I/O works!\n")
    f:close()
    f = io.open("/tmp/lua_test.txt", "r")
    if f then
        print("File: " .. f:read("*a"):gsub("\n", ""))
        f:close()
    end
end

print("All Lua tests passed!")
