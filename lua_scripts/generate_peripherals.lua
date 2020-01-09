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

                local documentID = ""
                for i=1, #stype-2 do
                    documentID = documentID..stype[i]:lower().."_"
                end
                documentID = documentID..stype[#stype]:lower()

                ntable[k] = "["..stype[2].."/"..stype[#stype].."]("..documentID..".md)"
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
            file:write("\n\n")
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
                    file:write("\n\n")
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
                        print("Unusual default value in method", name, parentName)
                        ANSI.setGraphicsMode(0, 1, 36) --Cyan output
                    end
    
                    if argument.name then
                        if argument.default then
                            file:write("\\["..argument.name.."] ("..convertType(argument.type)..")")
                            file:write(" (Default:`"..argument.default.."`)")
                        else
                            file:write("\\<"..argument.name.."> ("..convertType(argument.type)..")")
                        end
    
                        if argument.description then
                            file:write(":** "..argument.description.."\n")
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
                        file:write(":** "..ret.description.."\n")
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
                    print("Unusual default value in method", name, parentName)
                    ANSI.setGraphicsMode(0, 1, 36) --Cyan output
                end

                if argument.name then
                    if argument.default then
                        file:write("["..argument.name.."] ("..convertType(argument.type)..")")
                        file:write(" (Default:`"..argument.default.."`)")
                    else
                        file:write("\\<"..argument.name.."> ("..convertType(argument.type)..")")
                    end

                    if argument.description then
                        file:write(":** "..argument.description.."\n")
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
                    file:write(":** "..ret.description.."\n")
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

--Gemerates lines of markdown documenting the provided field
local function generateField(file, parentName, name, field, level)
    level = level or 1 --Root heading level

    local function heading(sublevel)
        return string.rep("#", level+sublevel).." "
    end

    file:write("\n")
    file:write(heading(0)..parentName.."."..name)

    if field.shortDescription then
        file:write("\n")
        file:write(field.shortDescription.."\n")
    end

    if field.longDescription then
        file:write("\n")
        file:write(field.longDescription.."\n")
    end

    file:write("\n")
    file:write("* **Type:** "..convertType(field.type).."\n")
    file:write("* **Available since:** _"..parentName..":_ v"..table.concat(field.availableSince[1], ".")..", _LIKO-12:_ v"..table.concat(field.availableSince[2], ".").."\n")
    file:write("* **Last updated in:** _"..parentName..":_ v"..table.concat(field.lastUpdatedIn[1], ".")..", _LIKO-12:_ v"..table.concat(field.lastUpdatedIn[2], ".").."\n")

    if field.protected then
        file:write("\n")
        file:write("> The field is protected from writing on (attempting so would raise an error!).")
    end

    if field.notes then
        for k, note in ipairs(field.notes) do
            file:write("\n\n")
            file:write("> "..note:gsub("\n","\n> ").."\n")
        end
    end

    if field.extra then
        file:write("\n")
        file:write(heading(1).."Note:\n")
        file:write(field.extra)
    end
end

--Generates lines of markdown documenting the provided event
local function generateEvent(file, parentName, name, event, level)
    level = level or 1 --Root heading level

    local function heading(sublevel)
        return string.rep("#", level+sublevel).." "
    end

    file:write("\n")
    file:write(heading(0).."`"..name.."`")

    if event.shortDescription then
        file:write("\n")
        file:write(event.shortDescription.."\n")
    end

    if event.longDescription then
        file:write("\n")
        file:write(event.longDescription.."\n")
    end

    file:write("\n")
    file:write("* **Available since:** _"..parentName..":_ v"..table.concat(event.availableSince[1], ".")..", _LIKO-12:_ v"..table.concat(event.availableSince[2], ".").."\n")
    file:write("* **Last updated in:** _"..parentName..":_ v"..table.concat(event.lastUpdatedIn[1], ".")..", _LIKO-12:_ v"..table.concat(event.lastUpdatedIn[2], ".").."\n")

    if event.notes then
        for k, note in ipairs(event.notes) do
            file:write("\n\n")
            file:write("> "..note:gsub("\n","\n> ").."\n")
        end
    end

    file:write("```lua\n")
    file:write("function _"..name.."(")
    if event.arguments then
        for k, argument in ipairs(event.arguments) do
            if k ~= 1 then file:write(", ") end
            file:write(argument.name)
        end
    end
    file:write(")\n")
    file:write("\t--Content run when the event is triggered\n")
    file:write("end\n")
    file:write("```\n")

    if event.arguments then
        file:write("\n")
        file:write(heading(1).."Arguments:\n")
        file:write("\n")

        for k, argument in ipairs(event.arguments) do
            file:write("* **"..argument.name.." ("..convertType(argument.type)..")")

            if argument.description then
                file:write(":** "..argument.description.."\n")
            else
                file:write("**\n")
            end
        end
    end

    if event.extra then
        file:write("\n")
        file:write(heading(1).."Note:\n")
        file:write(event.extra)
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
        file:write("> The peripheral has no methods.\n")
    end

    if peripheral.events then
        file:write("\n")
        file:write(heading(1).."Events:\n")

        file:write("\n")
        file:write("> Please note that the example functions won't be called automatically,\n")
        file:write("> there must be some kind of an events handler for [CPU.pullEvent](peripherals_cpu.md#cpupullevent),\n")
        file:write("> check if the LIKO-12 OS you're using has one.\n")

        --Sort the events according to their names
        local eventsList = {}
        for eventName, event in pairs(peripheral.events) do
            table.insert(eventsList, eventName)
        end
        table.sort(eventsList)

        for k, eventName in ipairs(eventsList) do
            file:write("\n")
            file:write("---\n")
            file:write("\n")
            generateEvent(file, name, eventName, peripheral.events[eventName], level+2)
        end

        if peripheral.objects then
            file:write("\n")
            file:write("---\n")
        end
    end

    if peripheral.objects then
        file:write("\n")
        file:write(heading(1).."Objects:\n")

        --Sort the objects according to their names
        local objectsList = {}
        for objectName, object in pairs(peripheral.objects) do
            table.insert(objectsList, objectName)
        end
        table.sort(objectsList)

        for k, objectName in ipairs(objectsList) do
            file:write("- ["..objectName.."](".."peripherals_"..name:lower().."_"..objectName:lower()..".md)")

            if peripheral.objects[objectName].shortDescription then
                file:write(" - "..peripheral.objects[objectName].shortDescription)
            end

            file:write("\n")
        end
    end
end

for peripheralName, peripheral in pairs(documentation.Peripherals) do
    print("Generating the "..peripheralName.." peripheral")
    local documentID = "peripherals_"..peripheralName:lower()
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

--== Generate peripherals' objects documentation ==--

ANSI.setGraphicsMode(0, 1, 34) --Blue output
print("Generating peripherals' objects documentation...")
ANSI.setGraphicsMode(0, 1, 36) --Cyan output

local function generateObject(file, parentName, name, object, level)
    level = level or 1 --Root heading level

    local function heading(sublevel)
        return string.rep("#", level+sublevel).." "
    end

    if object.fullDescription then
        file:write("\n")
        file:write(object.fullDescription.."\n")
    elseif object.shortDescription then
        file:write("\n")
        file:write(object.shortDescription.."\n")
    end

    file:write("\n")
    file:write("* **Available since:** _"..parentName..":_ v"..table.concat(object.availableSince[1], ".")..", _LIKO-12:_ v"..table.concat(object.availableSince[2], ".").."\n")
    file:write("* **Last updated in:** _"..parentName..":_ v"..table.concat(object.lastUpdatedIn[1], ".")..", _LIKO-12:_ v"..table.concat(object.lastUpdatedIn[2], ".").."\n")

    if object.notes then
        for k, note in ipairs(object.notes) do
            file:write("\n\n")
            file:write("> "..note:gsub("\n","\n> ").."\n")
        end
    end

    if object.fields then
        file:write("\n")
        file:write(heading(1).."Fields:\n")
        
        --Sort the fields according to their names
        local fieldsList = {}
        for fieldName, method in pairs(object.fields) do
            table.insert(fieldsList, fieldName)
        end
        table.sort(fieldsList)

        for k, fieldName in ipairs(fieldsList) do
            file:write("\n")
            file:write("---\n")
            file:write("\n")
            generateField(file, name, fieldName, object.fields[fieldName], level+2)
        end

        file:write("\n")
        file:write("---\n")
    end

    if object.events then
        file:write("\n")
        file:write(heading(1).."Events:\n")
        
        --Sort the events according to their names
        local eventsList = {}
        for methodName, method in pairs(object.events) do
            table.insert(eventsList, methodName)
        end
        table.sort(eventsList)

        for k, methodName in ipairs(eventsList) do
            file:write("\n")
            file:write("---\n")
            file:write("\n")
            generateMethod(file, name, methodName, object.events[methodName], level+2)
        end
    else
        file:write("\n")
        file:write("> The object has no methods.\n")
    end

    if object.extra then
        file:write("\n")
        file:write(heading(1).."Note:\n")
        file:write(object.extra)
    end
end

for peripheralName, peripheral in pairs(documentation.Peripherals) do
    if peripheral.objects then
        for objectName, object in pairs(peripheral.objects) do
            print("Generating the "..peripheralName.."/"..objectName.." object")
            local documentID = "peripherals_"..peripheralName:lower().."_"..objectName:lower()
            local file = assert(io.open("docs/".. documentID ..".md", "w"))

            file:write("---\n")
            file:write("id: "..documentID.."\n")
            file:write("title: "..peripheralName.." - "..objectName.."\n")
            file:write("sidebar_label: "..peripheralName.." / "..objectName.."\n")
            file:write("---\n")
            file:write("\n")

            generateObject(file, peripheralName, objectName, object, 1)

            assert(file:close())
        end
    end
end

--== Updating the sidebar ==--

ANSI.setGraphicsMode(0, 1, 34) --Blue output
io.write("Updating the sidebar... ")

local sidebarFile = assert(io.open("website/sidebars.json", "r"))
local sidebarData = assert(sidebarFile:read("*a"))
assert(sidebarFile:close())

local objectsList = {}

local sidebar = JSON:decode(sidebarData)
for peripheralName, peripheral in pairs(documentation.Peripherals) do
    --Only add the peripheral to the sidebar if it doesn't exist

    local documentID = "peripherals_"..peripheralName:lower()

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

    if peripheral.objects then
        for objectName, object in pairs(peripheral.objects) do
            table.insert(objectsList, "peripherals_"..peripheralName:lower().."_"..objectName:lower())
        end
    end
end

for k, documentID in pairs(objectsList) do
    local found = false
    for k, v in pairs(sidebar.docs["Peripherals' Objects"]) do
        if v == documentID then
            found = true
            break
        end
    end

    if not found then
        table.insert(sidebar.docs["Peripherals' Objects"], documentID)
    end
end

table.sort(sidebar.docs.Peripherals)
table.sort(sidebar.docs["Peripherals' Objects"])

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