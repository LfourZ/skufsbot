local f = string.format
local fs = require("fs")
local longest = {0, 0, 0, 0}

local dumpText = true
local dumpMarkdown = true
local dumpDiscordiaApi = true
local prettyMarkdown = true
local linkifyMarkdown = false
local updateViaGit = true

local ownerName = "hammerandchisel"
local repoName = "discord-api-docs"
local outputFilename = "endpoints"
local matches = {"GET", "POST", "PATCH", "PUT", "DELETE"}

local lines = {}

local function parseFiles(path)
	for fileName, fileType in fs.scandirSync(path) do
		 if fileType == "file" then
			local file = io.open(path .. "/" .. fileName)
			for line in file:lines() do
				for _, match in ipairs(matches) do
					if line:find(match) and line:find("##") then
						line = line:gsub("[%c\\]", ""):gsub("#%w.-}", "}"):gsub("## ", "")
						local name = line:match(".*%%"):gsub(" %%", ""):gsub('#', "")
						local method = line:match("%% %S+"):gsub("%% ", "")
						local url = line:match("%%.*"):gsub("%% %S+ ", ""):gsub("{@me}", "@me")
						local length = {name:len(), method:len(), url:len()}
						longest[1] = length[1] > longest[1] and length[1] or longest[1]
						longest[2] = length[2] > longest[2] and length[2] or longest[2]
						longest[3] = length[3] > longest[3] and length[3] or longest[3]
						if linkifyMarkdown then
							local link = "[" .. name .. "]" .. "(#" .. fileName:gsub(".md", "") .. "/" .. name:gsub(" ", "-") .. ")"
							local length = link:len()
							longest[4] = length > longest[4] and length or longest[4]
							table.insert(lines, {name, method, url, link})
						else
							table.insert(lines, {name, method, url})
						end
						break
					end
				end
			end
		else
			parseFiles(path .. "/" .. fileName)
		end
	end
end

local function sortLines(lines, n, m)
	table.sort(lines, function(a, b)
		if a[n] == b[n] then return a[m] < b[m] else return a[n] < b[n] end
	end)
end

local function writeLua(lines, file)
	for _, line in ipairs(lines) do
		local name = line[1]:gsub('^.', string.lower):gsub(' ', ''):gsub('/Close', '')
		local method = line[2]
		local url = line[3]:gsub('{.-}', '%%s')
		local args = {}
		for m in line[3]:gmatch('{.-}') do
			local arg = m:gsub('%.', '_'):gsub('{', ''):gsub('}', '')
			table.insert(args, arg)
		end
		if method == 'GET' or method == 'DELETE' then
			if #args > 0 then
				local args = table.concat(args, ', ')
				file:write(f("function API:%s(%s)\n", name, args))
				file:write(f("\treturn self:request(%q, url(%q, %s))\n", method, url, args))
			else
				file:write(f("function API:%s()\n", name))
				file:write(f("\treturn self:request(%q, url(%q))\n", method, url))
			end
		else
			if #args > 0 then
				local args = table.concat(args, ', ')
				file:write(f("function API:%s(%s, body)\n", name, args))
				file:write(f("\treturn self:request(%q, url(%q, %s), body or emptyBody)\n", method, url, args))
			else
				file:write(f("function API:%s(body)\n", name))
				file:write(f("\treturn self:request(%q, url(%q), body or emptyBody)\n", method, url))
			end
		end
		file:write("end\n\n")
	end
	file:write("\r\n")
end

local function writeText(lines, file)
	for _, line in ipairs(lines) do
		file:write(
			line[1] .. string.rep(" ", longest[1] - line[1]:len() + 4) ..
			line[2] .. string.rep(" ", longest[2] - line[2]:len() + 4) ..
			line[3] .. string.rep(" ", longest[3] - line[3]:len() + 4) .. "\r\n"
		)
	end
	file:write("\r\n")
end

local function writeMarkdown(lines, file)
	if prettyMarkdown then
		local i = linkifyMarkdown and 4 or 1
		file:write(
			"| Name" .. string.rep(" ", longest[i] - 4) ..
			" | Method" .. string.rep(" ", longest[2] - 6) ..
			" | Endpoint" .. string.rep(" ", longest[3] - 8) .. " |\r\n" ..
			"| " .. string.rep("-", longest[i]) ..
			" | " .. string.rep("-", longest[2]) ..
			" | " .. string.rep("-", longest[3]) .. " |\r\n"
		)
		for _, line in ipairs(lines) do
			file:write(
				"| " .. line[i] .. string.rep(" ", longest[i] - line[i]:len()) ..
				" | " .. line[2] .. string.rep(" ", longest[2] - line[2]:len()) ..
				" | " .. line[3] .. string.rep(" ", longest[3] - line[3]:len()) .. " |\r\n"
			)
		end
	else
		file:write(
			"| Name | Method | URL |\r\n|---|---|---|\r\n"
		)
		for _, line in ipairs(lines) do
			file:write(
				"|" .. table.concat(line, "|") .. "|\r\n"
			)
		end
	end
	file:write("\r\n")
end

if updateViaGit then
	if not fs.existsSync(repoName) then
		print("Directory not found, cloning from GitHub...")
		os.execute("git clone https://github.com/" .. ownerName .. "/" .. repoName .. ".git")
	else
		print("Directory found, updating via GitHub...")
		os.execute("git -C " .. repoName .. " pull")
	end
	if not fs.existsSync(repoName) then
		print("Could not find or download Discord documentation.")
		os.exit(1)
	end
end

print("Parsing documentation...")
parseFiles(repoName)

if dumpDiscordiaApi then
	local file = io.open(outputFilename .. ".lua", "w")
	writeLua(lines, file)
	file:close()
end

if dumpText then

	local file = io.open(outputFilename .. ".txt", "w")
	local breakLine = string.rep("-", longest[1] + longest[2] + longest[3])

	file:write("Updated: " .. os.date('!%Y-%m-%d %H:%M:%S') .. "\r\n\r\n")

	sortLines(lines, 1, 2)
	file:write("Sorted By Name\r\n" .. breakLine .. "\r\n")
	writeText(lines, file)

	sortLines(lines, 2, 3)
	file:write("Sorted By Method\r\n" .. breakLine .. "\r\n")
	writeText(lines, file)

	sortLines(lines, 3, 2)
	file:write("Sorted By URL\r\n" .. breakLine .. "\r\n")
	writeText(lines, file)

	file:close()

end

if dumpMarkdown then
	local file = io.open(outputFilename .. ".md", "w")
	sortLines(lines, 1, 2)
	writeMarkdown(lines, file)
	file:close()
end

print("Documentation parsed")
