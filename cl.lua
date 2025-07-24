--[[
            Copyright 2025, Vitali Baumtrok.
   Distributed under the Boost Software License, Version 1.0.
       (See accompanying file LICENSE or copy at
          http://www.boost.org/LICENSE_1_0.txt)
]]

local function extractSearchParams(paramsN, ...)
	local searchTerms, searchTermsN = nil, 0
	for i = 1, paramsN do
		local param = select(i, ...)
		if type(param) == "string" then
			searchTermsN = searchTermsN+1
			if searchTerms == nil then
				searchTerms = {param}
			else
				searchTerms[searchTermsN] = param
			end
		end
	end
	return searchTerms, searchTermsN
end

local function matchByPrefix(argument, argumentN, searchTerm, searchTermN, delimiter)
	local delimiterN, hasEmpty = delimiter.n, delimiter.hasEmpty
	if (delimiterN > 0 or hasEmpty) and string.sub(argument, 1, searchTermN) == searchTerm then
		for i = 1, delimiterN do
			local dlmtr = delimiter[i]
			local dlmtrN = #dlmtr
			local searchTermWithDlmtrN = searchTermN+dlmtrN
			if argumentN >= searchTermWithDlmtrN then
				local dlmtrInArgument = string.sub(argument, searchTermN+1, searchTermWithDlmtrN)
				if dlmtrInArgument == dlmtr then
					return string.sub(argument, searchTermWithDlmtrN+1, argumentN)
				end
			end
		end
		if hasEmpty then
			return string.sub(argument, searchTermN+1)
		end
	end
	return nil
end

local function searchPairsWithSpace(cmdLine, args, searchTerms, searchTermsN, delimiter)
	local arguments, matched, argumentsN = cmdLine.arguments, cmdLine.matched, cmdLine.n
	local keys, values, argsN = args.keys, args.values, args.n
	local i, allMatched = 1, true
	while i <= argumentsN do
		if not matched[i] then
			local argument = arguments[i]
			local argumentN = #argument
			for j = 1, searchTermsN do
				local searchTerm = searchTerms[j]
				local searchTermN = #searchTerm
				if argumentN == searchTermN then
					if argument == searchTerm then
						local value, iNxt = "", i+1
						matched[i] = true
						if iNxt <= argumentsN and not matched[iNxt] then
							value = arguments[iNxt]
							matched[iNxt] = true
							i = iNxt
						end
						argsN = argsN+1
						keys[argsN], values[argsN] = searchTerm, value
						break
					end
				elseif argumentN > searchTermN then
					local value = matchByPrefix(argument, argumentN, searchTerm, searchTermN, delimiter)
					if value then
						matched[i] = true
						argsN = argsN+1
						keys[argsN], values[argsN] = searchTerm, value
						break
					end
				end
			end
			allMatched = allMatched and matched[i]
		end
		i = i+1
	end
	matched[argumentsN+1] = allMatched
	args.n = argsN
end

local function searchPairsWithoutSpace(cmdLine, args, searchTerms, searchTermsN, delimiter)
	local arguments, matched, argumentsN, hasEmptyDelimiter = cmdLine.arguments, cmdLine.matched, cmdLine.n, delimiter.hasEmpty
	local keys, values, argsN = args.keys, args.values, args.n
	local i, allMatched = 1, true
	for i = 1, argumentsN do
		if not matched[i] then
			local argument = arguments[i]
			local argumentN = #argument
			for j = 1, searchTermsN do
				local searchTerm = searchTerms[j]
				local searchTermN = #searchTerm
				if argumentN == searchTermN then
					if hasEmptyDelimiter and argument == searchTerm then
						matched[i] = true
						argsN = argsN+1
						keys[argsN], values[argsN] = argument, ""
						break
					end
				elseif argumentN > searchTermN then
					local value = matchByPrefix(argument, argumentN, searchTerm, searchTermN, delimiter)
					if value then
						matched[i] = true
						argsN = argsN+1
						keys[argsN], values[argsN] = searchTerm, value
						break
					end
				end
			end
			allMatched = allMatched and matched[i]
		end
	end
	matched[argumentsN+1] = allMatched
	args.n = argsN
end

local function search_func(cmdLine, ...)
	local args = {keys = {}, values = {}, n = 0}
	local matched, argumentsN = cmdLine.matched, cmdLine.n
	if not matched[argumentsN+1] then
		local paramsN = select("#", ...)
		if argumentsN > 0 and paramsN > 0 then
			local searchTerms, searchTermsN, delimiter = extractSearchParams(paramsN, ...)
			if searchTermsN > 0 then
				local arguments, delimiter, allMatched = cmdLine.arguments, cmdLine.delimiter, true
				if delimiter == nil or not delimiter.active then
					local keys, argsN = args.keys, 0
					for i = 1, argumentsN do
						if not matched[i] then
							for j = 1, searchTermsN do
								local argument = arguments[i]
								if argument == searchTerms[j] then
									local argsNNxt = argsN+1
									keys[argsNNxt], argsN, matched[i] = argument, argsNNxt, true
									break
								end
							end
							allMatched = allMatched and matched[i]
						end
					end
					matched[argumentsN+1] = allMatched
					args.n = argsN
				else
					if delimiter.hasSpace then
						searchPairsWithSpace(cmdLine, args, searchTerms, searchTermsN, delimiter)
					else
						searchPairsWithoutSpace(cmdLine, args, searchTerms, searchTermsN, delimiter)
					end
				end
			end
		end
	end
	return args
end

local function unmatched_func(cmdLine)
	local args, argsN = {}, 0
	local arguments, matched, argumentsN = cmdLine.arguments, cmdLine.matched, cmdLine.n
	if not matched[argumentsN+1] then
		for i = 1, argumentsN do
			if not matched[i] then
				argsN = argsN+1
				args[argsN] = arguments[i]
			end
		end
	end
	args.n = argsN
	return args
end

local function newCmdLine_func(args, ...)
	local from, to
	local cmdLine = {arguments = {}, matched = {}, n = 0}
	local optsN = select("#", ...)
	if optsN > 0 then
		local opt1 = select(1, ...)
		if type(opt1) == "number" then
			if opt1 > 0 then
				from = opt1
			else
				from = 1
			end
		else
			error("2nd parameter not a number")
		end
		if optsN > 1 then
			local opt2 = select(2, ...)
			if type(opt2) == "number" then
				if opt2 > 0 then
					to = opt2
				else
					to = 0
				end
			else
				error("3nd parameter not a number")
			end
		else
			to = #args
		end
	else
		from, to = 1, #args
	end
	for i = from, to do
		local indexNew = i-from+1
		cmdLine.arguments[indexNew] = args[i]
		cmdLine.matched[indexNew] = false
	end
	cmdLine.n = to-from+1
	-- last value means all arguments are matched
	cmdLine.matched[cmdLine.n+1] = (cmdLine.n == 0)
	cmdLine.search = search_func
	cmdLine.unmatched = unmatched_func
	return cmdLine
end

local function newDelimiter_func(active, ...)
	local delimiter, n, hasEmpty, hasSpace, paramsN = {}, 0, false, false, select("#", ...)
	for i = 1, paramsN do
		local value = select(i, ...)
		if type(value) == "string" then
			if value == " " then
				hasSpace = true
			elseif value == "" then
				hasEmpty = true
			else
				n = n+1
				delimiter[n] = value
			end
		end
	end
	delimiter.n, delimiter.hasEmpty, delimiter.hasSpace, delimiter.active = n, hasEmpty, hasSpace, active
	return delimiter
end

return {newCmdLine = newCmdLine_func, newDelimiter = newDelimiter_func}
