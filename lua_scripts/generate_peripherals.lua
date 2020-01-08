--This script merges the files Engine_Documentation directory except the Media directory into a single .json file
--Specification Implemented: 2019-11-17-Specification.md

--Code author: Rami Sabbagh (RamiLego4Game)

--Extend the package path so it search for the modules in the special directory.
package.path = "./lua_scripts/modules/?.lua;./lua_scripts/modules/?/init.lua;"..package.path

local startClock = os.clock()

--Load ANSI module
if not pcall(require, "ANSI") then print("\27[0;1;31mCould not load the ANSI module, please make sure that the script is executed with the repository being the working directory!\27[0;1;37m") os.exit(1) return end
local ANSI = require("ANSI")

--== Shared functions ==--

local function fail(...)
	local reason = {...}
	for k,v in pairs(reason) do reason[k] = tostring(v) end
	reason = table.concat(reason, " ")
	ANSI.setGraphicsMode(0, 1, 31) --Red output
	print(reason)
	ANSI.setGraphicsMode(0, 1, 37) --White output
	os.exit(1)
end

local function isFile(path)
	local mode, err = lfs.attributes(path, "mode")
	return mode and mode == "file"
end

local function isDirectory(path)
	local mode, err = lfs.attributes(path, "mode")
	return mode and mode == "directory"
end

--== Load external modules ==--

if not pcall(require, "lfs") then fail("Could not load luafilesystem, please make sure it's installed using luarocks first!") end
local lfs = require("lfs")
if not pcall(require, "JSON") then fail("Could not load JSON module, please make sure that the script is executed with the repository being the working directory!") end
local JSON = require("JSON")

--== Script Introduction ==--

ANSI.setGraphicsMode(0, 37) --Light grey output
print("")
print("Peripherals documentation generation script (generate_peripherals.lua) by Rami Sabbagh (RamiLego4Game)")
print("Using specification 2019-11-17")
print("")

--== Loading the documentation ==--

ANSI.setGraphicsMode(0, 1, 34) --Blue output
io.write("Loading the documention JSON... ")

local documentation = {} --The loaded documentation table form the engine.json file
do
    local engineFile = assert(io.open("lua_scripts/data/engine.json", "r"))
    local engineJSON = assert(engineFile:read("*a"))
    assert(engineFile:close())

    documentation = JSON:decode(engineJSON)
end

ANSI.setGraphicsMode(0, 1, 32) --Green output
print("Loaded.")

--== Generating the peripherals documentation ==--

ANSI.setGraphicsMode(0, 1, 34) --Blue output
print("Generating peripherals documentation...")
ANSI.setGraphicsMode(0, 1, 36) --Cyan output

--Generates a link or a string for a type
local function convertType(atype)
    if type(atype) == "table" then
        local ntable = {}

        for k, stype in ipairs(atype) do
            if type(stype) == "table" then --Complex type
                --TODO: COMPLEX TYPE PROPER LINKING
                ntable[k] = stype[#stype]
            else
                ntable[k] = stype
            end
        end

        return table.concat(ntable, ", ")
    else
        return atype
    end
end

--Generates lines of markdown documenting the provided method
local function generateMethod(file, parentName, name, method, level)
    level = level or 1 --Root heading level

    local function heading(sublevel)
        return string.rep("#", level+sublevel).." "
    end

    file:write(heading(0)..parentName .. (method.self and ":" or ".") .. name.."\n")

    if method.shortDescription then
        file:write("\n")
        file:write(method.shortDescription.."\n")
    end

    if method.longDescription then
        file:write("\n")
        file:write(method.longDescription.."\n")
    end

    file:write("\n")
    file:write("* **Available since:** _"..parentName..":_ v"..table.concat(method.availableSince[1], ".")..", _LIKO-12:_ v"..table.concat(method.availableSince[2], ".").."\n")
    file:write("* **Last updated in:** _"..parentName..":_ v"..table.concat(method.lastUpdatedIn[1], ".")..", _LIKO-12:_ v"..table.concat(method.lastUpdatedIn[2], ".").."\n")

    if method.notes then
        for k, note in ipairs(method.notes) do
            file:write("\n")
            file:write("> "..note:gsub("\n","\n> ").."\n")
        end
    end

    if method.usages then
        file:write("\n")
        file:write(heading(1).."Usages:\n")

        for k, usage in ipairs(method.usages) do
            file:write("\n")
            file:write("---\n")
            file:write("\n")
            file:write(heading(2)..k..". "..usage.name.."\n")

            if usage.shortDescription then
                file:write("\n")
                file:write(usage.shortDescription.."\n")
            end
        
            if usage.longDescription then
                file:write("\n")
                file:Write(usage.longDescription.."\n")
            end

            if usage.note then
                usage.notes = usage.notes or {}
                table.insert(usage.notes, usage.note)
                usage.note = nil
            end

            if usage.notes then
                for k, note in ipairs(usage.notes) do
                    file:write("\n")
                    file:write("> "..note:gsub("\n","\n> ").."\n")
                end
            end

            file:write("\n")
            file:write("```lua\n")
            if usage.returns then
                for k, ret in ipairs(usage.returns) do
                    if k ~= 1 then file:write(", ") end
                    file:write(ret.name)
                end
                file:write(" = ")
            end
            file:write(parentName .. (method.self and ":" or ".") ..name.."(")
            if usage.arguments then
                for k, argument in ipairs(usage.arguments) do
                    if k ~= 1 then file:write(", ") end
                    file:write(argument.name or argument.default)
                end
            end
            file:write(")\n")
            file:write("```\n")

            if usage.arguments then
                file:write("\n")
                file:write(heading(3).."Arguments:\n")
                file:write("\n")
    
                for k, argument in ipairs(usage.arguments) do
                    file:write("* **")

                    --TODO: Remove this debug
                    if argument.default and argument.default ~= "false" and argument.default ~= "true" and argument.default ~= "nil" and not tonumber(argument.default) and argument.default:sub(1,1) ~= "\"" then
                        ANSI.setGraphicsMode(0, 1, 33) --Orange output
                        print("Improper default value in method", name, parentName)
                        ANSI.setGraphicsMode(0, 1, 36) --Cyan output
                    end
    
                    if argument.name then
                        file:write(argument.name.." ("..convertType(argument.type)..")")
                        if argument.default then
                            file:write(" (Default:`"..argument.default.."`)")
                        end
    
                        if argument.description then
                            file:write(":** "..argument.description..".\n")
                        else
                            file:write("**\n")
                        end
                    else --Literal value
                        file:write("`"..argument.default.."` ("..convertType(argument.type)..")**\n")
                    end
                end
            end

            if usage.returns then
                file:write("\n")
                file:write(heading(3).."Returns:\n")
                file:write("\n")
    
                for k, ret in ipairs(usage.returns) do
                    file:write("* **"..ret.name.." ("..convertType(ret.type)..")")
    
                    if ret.description then
                        file:write(":** "..ret.description..".\n")
                    else
                        file:write("**\n")
                    end
                end
            end

            if usage.extra then
                file:write("\n")
                file:write(heading(3).."Note:\n")
                file:write(usage.extra)
            end
        end
    else
        file:write("\n")
        file:write("```lua\n")
        if method.returns then
            for k, ret in ipairs(method.returns) do
                if k ~= 1 then file:write(", ") end
                file:write(ret.name)
            end
            file:write(" = ")
        end
        file:write(parentName .. (method.self and ":" or ".") ..name.."(")
        if method.arguments then
            for k, argument in ipairs(method.arguments) do
                if k ~= 1 then file:write(", ") end
                file:write(argument.name or argument.default)
            end
        end
        file:write(")\n")
        file:write("```\n")

        if method.arguments then
            file:write("\n")
            file:write(heading(1).."Arguments:\n")
            file:write("\n")

            for k, argument in ipairs(method.arguments) do
                file:write("* **")

                --TODO: Remove this debug
                if argument.default and argument.default ~= "false" and argument.default ~= "true" and argument.default ~= "nil" and not tonumber(argument.default) and argument.default:sub(1,1) ~= "\"" then
                    ANSI.setGraphicsMode(0, 1, 33) --Orange output
                    print("Improper default value in method", name, parentName)
                    ANSI.setGraphicsMode(0, 1, 36) --Cyan output
                end

                if argument.name then
                    file:write(argument.name.." ("..convertType(argument.type)..")")
                    if argument.default then
                        file:write(" (Default:`"..argument.default.."`)")
                    end

                    if argument.description then
                        file:write(":** "..argument.description..".\n")
                    else
                        file:write("**\n")
                    end
                else --Literal value
                    file:write("`"..argument.default.."` ("..convertType(argument.type)..")**\n")
                end
            end
        end

        if method.returns then
            file:write("\n")
            file:write(heading(1).."Returns:\n")
            file:write("\n")

            for k, ret in ipairs(method.returns) do
                file:write("* **"..ret.name.." ("..convertType(ret.type)..")")

                if ret.description then
                    file:write(":** "..ret.description..".\n")
                else
                    file:write("**\n")
                end
            end
        end
    end

    if method.extra then
        file:write("\n")
        file:write(heading(1).."Note:\n")
        file:write(method.extra)
    end
end

--Generates lines of markdown documenting the provided peripheral
local function generatePeripheral(file, name, peripheral, level)
    level = level or 1 --Root heading level

    local function heading(sublevel)
        return string.rep("#", level+sublevel).." "
    end

    file:write("\n")
    file:write((peripheral.fullDescription or peripheral.shortDescription).."\n")

    file:write("\n")
    file:write("* **Version:** v"..table.concat(peripheral.version, ".").."\n")
    file:write("* **Available since:** LIKO-12 v"..table.concat(peripheral.availableSince, ".").."\n")
    file:write("* **Last updated in:** LIKO-12 v"..table.concat(peripheral.lastUpdatedIn, ".").."\n")

    if peripheral.methods then
        file:write("\n")
        file:write(heading(1).."Methods:\n")
        
        --Sort the methods according to their names
        local methodsList = {}
        for methodName, method in pairs(peripheral.methods) do
            table.insert(methodsList, methodName)
        end
        table.sort(methodsList)

        for k, methodName in ipairs(methodsList) do
            file:write("\n")
            file:write("---\n")
            file:write("\n")
            generateMethod(file, name, methodName, peripheral.methods[methodName], level+2)
        end
    else
        file:write("\n")
        file:write("> This peripheral has no methods.\n")
    end
end

for peripheralName, peripheral in pairs(documentation.Peripherals) do
    print("Generating the "..peripheralName.." peripheral")
    local documentID = "peripheral_"..peripheralName:lower()
    local file = assert(io.open("docs/".. documentID ..".md", "w"))

    local title = peripheralName
    if peripheral.name and peripheral.name ~= peripheralName then title = title .. " - "..peripheral.name end

    file:write("---\n")
    file:write("id: "..documentID.."\n")
    file:write("title: "..title.."\n")
    file:write("sidebar_label: "..title.."\n")
    file:write("---\n")
    file:write("\n")

    generatePeripheral(file, peripheralName, peripheral, 1)

    assert(file:close())
end

--== Updating the sidebar ==--

ANSI.setGraphicsMode(0, 1, 34) --Blue output
io.write("Updating the sidebar... ")

local sidebarFile = assert(io.open("website/sidebars.json", "r"))
local sidebarData = assert(sidebarFile:read("*a"))
assert(sidebarFile:close())

local sidebar = JSON:decode(sidebarData)
for peripheralName, peripheral in pairs(documentation.Peripherals) do
    --Only add the peripheral to the sidebar if it doesn't exist

    local documentID = "peripheral_"..peripheralName:lower()

    local found = false
    for k, v in pairs(sidebar.docs.Peripherals) do
        if v == documentID then
            found = true
            break
        end
    end

    if not found then
        table.insert(sidebar.docs.Peripherals, documentID)
    end
end
table.sort(sidebar.docs.Peripherals)

sidebarData = JSON:encode_pretty(sidebar, _, {
    pretty = true,
    array_newline  = true,
    indent = "  "
})

sidebarFile = assert(io.open("website/sidebars.json", "w"))
assert(sidebarFile:write(sidebarData))
assert(sidebarFile:flush())

ANSI.setGraphicsMode(0, 1, 32) --Green output
print("Done.")

--== The end of the script ==--

local endClock = os.clock()
local executionTime = endClock - startClock

ANSI.setGraphicsMode(0, 1, 32) --Green output
print("")
print("The peripherals documentation has been generated successfully in "..executionTime.."s.")
print("")

ANSI.setGraphicsMode(0, 1, 37) --White output