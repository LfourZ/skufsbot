local M = {}

local function randomTableElement(Table)
	return Table[math.random(1, #Table)]
end
M.randomTableElement = randomTableElement

local function numKeys(Table)
	local num = 0
	for _ in pairs(Table) do
		num = num + 1
	end
	return num
end
M.numKeys = numKeys

local function containsKey(Table, Key)
	return Table[Key] ~= nil
end
M.containsKey = containsKey

local function checkForEntry(Table, String)
	local found = false
	for k, v in pairs(Table) do
		if string.find(String, k) == 1 then
			found = true
			break
		end
	end
	return found
end
M.checkForEntry = checkForEntry

local function printKeys(Table)
	if type(Table) ~= "table" then return end
	for k, v in pairs(Table) do
		print(k)
	end
end
M.printKeys = printKeys

local function printTableData(Table)
	local spacing = 20
	if type(Table) ~= "table" then return end
	for k, v in pairs(Table) do
		if type(v) == "number" then
			v = tonumber(v)
		elseif type(v) == "boolean" then
			if v then
				v = "true"
			else
				v = "false"
			end
		elseif type(v) == "table" then
			local vd = v
			v = ""
			for kr, vr in pairs(vd) do
				if type(vr) == "number" then
					vr = tonumber(vr)
				elseif type(vr) == "boolean" then
					if vr then
						vr = "true"
					else
						vr = "false"
					end
				elseif type(vr) ~= "string" then
					vr = type(vr)
				end
				v = v.."   "..kr..":"..vr
			end
		elseif type(v) ~= "string" then
			v = type(v)
		end
		if type(k) == "string" then
			print(k..string.rep(" ", spacing - string.len(k))..v)
		else
			print(k..string.rep(" ", spacing - string.len(tostring(k)))..v)
		end
	end
end
M.printTableData = printTableData

return M