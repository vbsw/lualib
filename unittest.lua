--[[
            Copyright 2025, Vitali Baumtrok.
   Distributed under the Boost Software License, Version 1.0.
       (See accompanying file LICENSE or copy at
          http://www.boost.org/LICENSE_1_0.txt)
]]

local cl = require("cl")

local function asserType(obj, expectedType)
	local objType = type(obj)
	if objType ~= expectedType then
		error("is type \""..objType.."\" (instead of \""..expectedType"\")", 2)
	end
end

local function assertMemberType(obj, expectedKeys, expectedValueTypes)
	for i = 1, #expectedKeys do
		local expectedKey, foundValue, found = expectedKeys[i], nil, false
		for key, value in pairs(obj) do
			if key == expectedKey then
				foundValue, found = value, true
				break
			end
		end
		if found then
			local foundValueType, expectedValueType = type(foundValue), expectedValueTypes[i]
			if foundValueType ~= expectedValueType then
				error("key \""..expectedKey.."\" is type \""..foundValueType.."\" (instead of \""..expectedValueType"\")", 2)
			end
		else
			error("is key \""..expectedKey.."\" missing (instead of available)", 2)
		end
	end
end

local function assertGr(value, expectedValue)
	if value <= expectedValue then
		local valueType = type(value)
		if valueType == "string" then
			local is = "is \""..value.."\" <= \""..expectedValue.."\""
			local insteadOf = " (instead of \""..value.."\" > \""..expectedValue.."\")"
			error(has..insteadOf, 2)
		else
			local is = "is "..value.." <= "..expectedValue
			local insteadOf = " (instead of "..value.." > "..expectedValue..")"
			error(has..insteadOf, 2)
		end
	end
end

local function assertEq(value, expectedValue)
	if value ~= expectedValue then
		local valueType = type(value)
		if valueType == "string" then
			error("is \""..value.."\" (instead of \""..expectedValue.."\")", 2)
		else
			error("is "..tostring(value).." (instead of "..tostring(expectedValue)..")", 2)
		end
	end
end

local function assertArryEq(value, expectedValues)
	for i, val in ipairs(value) do
		local expectedValue = expectedValues[i]
		local valType, expectedValueType = type(val), type(expectedValue)
		if valType ~= expectedValueType then
			error("index "..i.." is type \""..valType.."\" (instead of \""..expectedValueType"\")", 2)
		elseif val ~= expectedValue then
			if valType == "string" then
				error("index "..i.." is \""..val.."\" (instead of \""..expectedValue.."\")", 2)
			else
				error("index "..i.." is "..tostring(val).." (instead of "..tostring(expectedValue)..")", 2)
			end
		end
	end
end

function testCL()
	local cmdLine = cl.newCmdLine({"asdf", "--version"})
	asserType(cmdLine, "table")
	assertMemberType(cmdLine, {"arguments", "matched", "n"}, {"table", "table", "number"})
	assertEq(#cmdLine.arguments, 2)
	assertEq(#cmdLine.matched, 3)
	assertEq(cmdLine.n, 2)
	assertArryEq(cmdLine.matched, {false, false, false})
	local argument = cmdLine:search("-v", "--version")
	asserType(argument, "table")
	assertMemberType(argument, {"keys", "values", "n"}, {"table", "table", "number"})
	assertEq(#argument.keys, 1)
	assertEq(#argument.values, 0)
	assertEq(argument.n, 1)
	assertEq(argument.keys[1], cmdLine.arguments[2])
	assertArryEq(cmdLine.matched, {false, true, false})

	cmdLine = cl.newCmdLine({"--start", "asdf", "-s", "qwer"})
	assertEq(cmdLine.n, 4)
	argument = cmdLine:search("-s", "--start")
	assertEq(argument.n, 2)
	assertEq(argument.keys[1], cmdLine.arguments[1])
	assertEq(argument.keys[2], cmdLine.arguments[3])
	assertArryEq(cmdLine.matched, {true, false, true, false, false})

	cmdLine = cl.newCmdLine({"asdf", "--start=123"})
	assertEq(cmdLine.n, 2)
	cmdLine.delimiter = cl.newDelimiter(true, "=", "")
	asserType(cmdLine.delimiter, "table")
	assertMemberType(cmdLine.delimiter, {"hasEmpty", "hasSpace", "enabled", "n"}, {"boolean", "boolean", "boolean", "number"})
	assertEq(#cmdLine.delimiter, 1)
	assertEq(cmdLine.delimiter[1], "=")
	assertEq(cmdLine.delimiter.n, 1)
	assertEq(cmdLine.delimiter.hasEmpty, true)
	assertEq(cmdLine.delimiter.hasSpace, false)
	argument = cmdLine:search("-s", "--start")
	assertEq(argument.n, 1)
	assertEq(argument.values[1], "123")
	assertArryEq(cmdLine.matched, {false, true, false})

	cmdLine = cl.newCmdLine({"asdf", "--start", "123"})
	assertEq(cmdLine.n, 3)
	cmdLine.delimiter = cl.newDelimiter(true, " ", "=")
	assertEq(#cmdLine.delimiter, 1)
	assertEq(cmdLine.delimiter[1], "=")
	assertEq(cmdLine.delimiter.n, 1)
	assertEq(cmdLine.delimiter.hasEmpty, false)
	assertEq(cmdLine.delimiter.hasSpace, true)
	argument = cmdLine:search("-s", "--start")
	assertEq(argument.n, 1)
	assertEq(argument.values[1], "123")
	assertArryEq(cmdLine.matched, {false, true, true, false})

	cmdLine = cl.newCmdLine({"asdf", "--start123"})
	assertEq(cmdLine.n, 2)
	cmdLine.delimiter = cl.newDelimiter(true, "=", "")
	argument = cmdLine:search("-s", "--start")
	assertEq(argument.n, 1)
	assertEq(argument.values[1], "123")
	assertArryEq(cmdLine.matched, {false, true, false})

	cmdLine = cl.newCmdLine({"--start", "asdf", "-s", "qwer"})
	assertEq(cmdLine.n, 4)
	argument = cmdLine:search("--start", "-s")
	assertArryEq(cmdLine.matched, {true, false, true, false, false})
	local unmatched = cmdLine:unmatched()
	assertEq(unmatched.n, 2)
	assertEq(unmatched[1], cmdLine.arguments[2])
	assertEq(unmatched[2], cmdLine.arguments[4])
	cmdLine:search("asdf", "qwer")
	assertArryEq(cmdLine.matched, {true, true, true, true, true})
end

function testLib()
	testCL()
end
