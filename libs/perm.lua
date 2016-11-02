local M = {}

--Users, roles and channels that get instant thumbs up for new commands
local ROOT_ROLE = "none"
local ROOT_USER = "184262286058323968"
local ROOT_CHANNEL = "none"

--Debug variable that prints execution location and a few other things
local DEBUG = true

--Global variable that contains all relevant server permission and other info
_G.perms = {}
_G.perms.servers = {}
_G.defcommands = {}

--These commands are added to any server with the above root role/user/channels
_G.defcommands["playerlist"] = {}
_G.defcommands["test"] = {}
_G.defcommands["permission"] = {}
_G.defcommands["whocanuse"] = {}
_G.defcommands["editelement"] = {}
_G.defcommands["printelement"] = {}

--Prints data found in path Message seperated by whitespaces.
local function printElement(String, Message)
	local str = string.gsub(String, "Server.id", Message.server.id)
	str = string.gsub(str, "Me.id", Message.author.id)
	local path = _G
	local returnstr = "```\n"
	for i in string.gmatch(str, "%S+") do
		path = path[i]
	end
	if type(path) == "string" then
		returnstr = returnstr..path
	elseif type(path) == "table" then
		for k, v in pairs(path) do
			returnstr = returnstr..k.."\n"
		end
	else
		returnstr = returnstr.."Path was type "..type(path)
	end
	returnstr = returnstr.."```"
	return returnstr
end
M.printElement = printElement



--A few requires
local xml = require("./tableToXml") --For table to xml
local ltable = require("./ltable") --For a few table functions
local httpfunctions = require("./httpFunctions") --For http functions and xml to table

--
local function ldebug(String)
	if not DEBUG then return end
	print(string.format("[%s]: %s", os.date("%c"), String))
end

--Checks if Char is one of the server's silent or loud character. This determines whether the command gets deleted
local function isSilent(Char, Server)
	ldebug(debug.getinfo(1, "n").name)
	if Char == _G.perms.servers[Server.id].data.silentchar then
		return true
	elseif Char == _G.perms.servers[Server.id].data.loudchar then
		return false
	else
		return nil
	end
end
M.isSilent = isSilent

--Checks Table for Id, if nothing is found, it defaults to Bool
local function checkForPerm(Table, Id, Bool) --DONE
	if DEBUG then print(debug.getinfo (1, "n").name) end
	local result = false
	if Table[Id] == "true" then
		result = true
	elseif Table[Id] == "false" then
		result = false
	else
		if DEBUG then 
			if Table[Id] == nil then
				print("ERROR: Unexpected perm result: nil. Defaulting to "..tostring(Bool))
			end
		end
		result = Bool
	end
	if result and DEBUG then
		print("^ allowed")
	else
		print("^ not allowed")
	end
	return result
end
M.defaultPerm = defaultPerm

--Function to check if file exists, used in other functions
local function fileExists(Name) --DONE
	if DEBUG then print(debug.getinfo (1, "n").name) end
   	local f=io.open(Name,"r")
   	if f~=nil then io.close(f) return true else return false end
end
M.fileExists = fileExists

--Overwrites XML file with permissions with whatever is currently in the permissions table
local function savePermFile(Server)
	if DEBUG then print(debug.getinfo (1, "n").name) end
	local file = io.open("./perms/perms_"..Server.id..".xml", "w")
	io.output(file)
	io.write(xml.tableToXml(_G.perms.servers[Server.id]))
	io.close(file)
end
M.savePermFile = savePermFile

--Creates table structure and default entries for a server, used for instance when new server is detected
local function generatePermTable(Server, Table) --I DUNNO
	if DEBUG then print(debug.getinfo (1, "n").name) end
	local tbl = {}
	tbl["data"] = {}
	tbl.data["silentchar"] = "/"
	tbl.data["loudchar"] = "!"
	tbl.data["servername"] = Server.name
	tbl.data["joinmsg"] = "User has joined the server"
	tbl.data["leavemsg"] = "User has left the server"
	tbl.data["msgchannel"] = Server.defaultChannel
	tbl.data["msgsettings"] = "0"
	tbl["commands"] = {}
	for k, v in pairs(Table) do
		tbl.commands[k] = {}
		tbl.commands[k].roles =  {}
		tbl.commands[k].roles[ROOT_ROLE] = true
		tbl.commands[k].channels = {}
		tbl.commands[k].channels[ROOT_CHANNEL] = true
		tbl.commands[k].users = {}
		tbl.commands[k].users[ROOT_USER] = true
	end
	_G.perms.servers[Server.id] = tbl
	savePermFile(Server)
end
M.generatePermTable = generatePermTable

--Registers a new Command on a Server. Called when default command doesn't exist on a server
local function addCommand(Command, Server)
	if DEBUG then print(debug.getinfo (1, "n").name) end
	_G.perms.servers[Server.id].commands[Command] = {}
	_G.perms.servers[Server.id].commands[Command].roles =  {}
	_G.perms.servers[Server.id].commands[Command].roles[ROOT_ROLE] = true
	_G.perms.servers[Server.id].commands[Command].channels = {}
	_G.perms.servers[Server.id].commands[Command].channels[ROOT_CHANNEL] = true
	_G.perms.servers[Server.id].commands[Command].users = {}
	_G.perms.servers[Server.id].commands[Command].users[ROOT_USER] = true
	savePermFile(Server)
end
M.addCommand = addCommand

--Converts XML with permissions for Server into table and loads it in the global table
local function loadPermFile(Server)
	if DEBUG then print(debug.getinfo (1, "n").name) end
	local file = io.open("./perms/perms_"..Server.id..".xml", "r")
	io.input(file)
	local tbl = httpfunctions.xmlToTable(io.read("*a"))
	_G.perms.servers[Server.id] = tbl.root
	io.close(file)
	return true
end
M.loadPermFile = loadPermFile

--Checks if Command exists on Server. If not, checks if Command is a default command, and if so, loads it
local function commandExists(Command, Server)
	if DEBUG then print(debug.getinfo (1, "n").name) end
	if _G.perms.servers[Server.id].commands[Command] ~= nil then
		if DEBUG then print("True") end
		return true
	else
		if _G.defcommands[Command] ~= nil then
			addCommand(Command, Server)
			if DEBUG then print("True") end
			return true
		else
			if DEBUG then print("False") end
			return false
		end
	end
end
M.commandExists = commandExists

--Checks for permission XML file for ALL servers, when server without file is found, generates server file with default commands
local function checkForPermFile(Client) --ALSO DONE
	if DEBUG then print(debug.getinfo (1, "n").name) end
	for k, v in pairs(Client.servers) do
		if not fileExists("./perms/perms_"..v.id..".xml") then
			generatePermTable(v, _G.defcommands)
		else
			loadPermFile(v)
		end
	end
end
M.checkForPermFile = checkForPermFile

--Checks if the permissions are loaded in the global table for Server
local function isPermsLoaded(Server) --DONE
	if DEBUG then print(debug.getinfo (1, "n").name) end
	if _G.perms.servers[Server.id] ~= nil then
		return true
	else
		return false
	end
end
M.isPermsLoaded = isPermsLoaded

--Takes two tables, and first cross checks the key. If match is found, the values are compared. If values also match,
--returns true or false (if found), and breaks. If values don't match, goes back to beginning. If nothing is found,
--return defaults to Bool
local function crossCheckKey(Table, Table2, Bool, Server)
	if DEBUG then print(debug.getinfo (1, "n").name) end
	local found = false
	local result = Bool
	for k, v in pairs(Table) do
		if found then break end
		for kr, vr in pairs(Table2) do
			if kr == k then
				if vr == "true" then
					found = true
					result = true
					break
				elseif vr == "false" then
					found = true
					result = false
					break
				else
					if DEBUG then print("ERROR: Unexpected perm value: "..vr) end
					found = true
				end
			end
		end
	end
	if Table2[Server.defaultRole.id] == "true" then
		result = true
	elseif Table2[Server.defaultRole.id] == "false" then
		result = false
	end
	if result and DEBUG then
		print("^ allowed")
	else
		print("^ not allowed")
	end
	return result
end
M.crossCheckKey = crossCheckKey

--Crosschecks the elements of two tables, returning true and ending when exact matches are found
local function crossCheckElement(Table, Table2) --READ ABOVE
	if DEBUG then print(debug.getinfo (1, "n").name) end
	local found = false
	for k, v in pairs(Table) do
		if found then break end
		for kr, vr in pairs(Table2) do
			if vr == v then
				found = true
				break
			end
		end
	end
	return found
end
M.crossCheckElement = crossCheckElement

--Checks if the user has a permitted role for a command, if nothing is found, defaults to false
local function roleAllowed(User, Command)
	return crossCheckKey(User.roles, _G.perms.servers[User.server.id].commands[Command].roles, false, User.server)
end
M.roleAllowed = roleAllowed

--Checks if exception exists for the user and command, if nothing is found, defaults to nil
local function userAllowed(User, Command)
	return checkForPerm(_G.perms.servers[User.server.id].commands[Command].users, User.id, nil)
end
M.userAllowed = userAllowed

--Checks if the channel (gotten from Message.channel). allows the Command. If nothing is found, defaults to true
local function channelAllowed(Message, Command)
	return checkForPerm(_G.perms.servers[Message.server.id].commands[Command].channels, Message.channel.id, true)
end
M.channelAllowed = channelAllowed

--Combines the three above functions to get an absolute value. role and channel have to be true, and user, if
--existant, overrides everything. This means that user permissions are for fine tuning.
local function canUse(Message, Command)
	print("canuse")
	ldebug(debug.getinfo(1, "n").name)
	local response = false
	if roleAllowed(Message.author, Command) then
		if channelAllowed(Message, Command) then
			response = true
		end
	end
	if userAllowed(Message.author, Command) ~= nil then
		response = userAllowed(Message.author, Command)
	end
	return response
end
M.canUse = canUse

--Changes permissions for everyone in the Table of mentions, depending on the Args. Returns string 'str' with
--info about the permission changes, formatted with backticks for discord
local function editPerms(Table, Args, Server)
	if DEBUG then print(debug.getinfo (1, "n").name) end
	local action, commande = string.match(Args, "(%S+) (%S+)")
	if not commandExists(commande, Server) then print("Command "..commande.." doesn't exist.") return end
	local str = "```\n"
	str = str.."Action "..action.." applied to command "..commande.." with members:\n"
	if action == "add" then
		action = "true"
	elseif action == "remove" then
		action = "false"
	elseif action == "clear" then
		action = nil
	end
	for k, v in pairs(Table.members) do
		_G.perms.servers[Server.id].commands[commande].users[v.id] = action
		str = str..v.name.." ("..v.id..")\n"
	end
	str = str.."Channels:\n"
	for k, v in pairs(Table.channels) do
		_G.perms.servers[Server.id].commands[commande].channels[v.id] = action
		str = str..v.name.." ("..v.id..")\n"
	end
	str = str.."Roles:\n"
	for k, v in pairs(Table.roles) do
		_G.perms.servers[Server.id].commands[commande].roles[v.id] = action
		str = str..v.name.." ("..v.id..")\n"
	end
	savePermFile(Server)
	str = str.."```"
	print(str)
	return str
end
M.editPerms = editPerms

local function whoCanUse(Command, Server, Client)
	print(Command)
	local str = "```\n"
	local allowed = ""
	if commandExists(Command, Server) == false then return end
	str = str.."Members who can/cannot use command "..Command..":\n"
	if type(_G.perms.servers[Server.id].commands[Command].users) == "table" then
		for k, v in pairs(_G.perms.servers[Server.id].commands[Command].users) do
			if v ~= "true" and v ~= "false" then
				print("hi")
			elseif v == "true" then
				allowed = "is allowed"
			else
				allowed = "is not allowed"
			end
			if Client:getMemberById(k) ~= nil then
				str = str..Client:getMemberById(k).name.." ("..k..") "..allowed.."\n"
			else
				if DEBUG then print("Invalid user ID found in "..Server.name) end
			end
		end
	end
	str = str.."Channels that can/cannot use command "..Command..":\n"
	if type(_G.perms.servers[Server.id].commands[Command].channels) == "table" then
		for k, v in pairs(_G.perms.servers[Server.id].commands[Command].channels) do
			if v ~= "true" and v ~= "false" then
				print("hi")
			elseif v == "true" then
				allowed = "is allowed"
			else
				allowed = "is not allowed"
			end
			if Client:getChannelById(k) ~= nil then
				str = str..Client:getChannelById(k).name.." ("..k..") "..allowed.."\n"
			else
				if DEBUG then print("Invalid channel ID found in "..Server.name) end
			end
		end
	end
	str = str.."Roles that can/cannot use command "..Command..":\n"
	if type(_G.perms.servers[Server.id].commands[Command].roles) == "table" then
		for k, v in pairs(_G.perms.servers[Server.id].commands[Command].roles) do
			if v ~= "true" and v ~= "false" then
				print("hi")
			elseif v == "true" then
				allowed = "is allowed"
			else
				allowed = "is not allowed"
			end
			if Client:getRoleById(k) ~= nil then
				str = str..Client:getRoleById(k).name.." ("..k..") "..allowed.."\n"
			else
				if DEBUG then print("Invalid role ID found in "..Server.name) end
			end
		end
	end
	str = str.."```"
	if DEBUG then print(str) end
	return str
end
M.whoCanUse = whoCanUse

return M



