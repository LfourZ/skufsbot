local M = {}

--A few requires
local ltable = require("./ltable") --For a few table functions
local httpfunctions = require("./httpFunctions") --For http functions and xml to table
local json = require("./json")
local mdata = require("./modules")

local MDATA = {
	modules = mdata.modules
}

--Users, roles and channels that get instant thumbs up for new commands
local ROOT_ROLE = nil
local ROOT_USER = "184262286058323968"
local ROOT_CHANNEL = nil

--Debug variable that prints execution location and a few other things
local DEBUG = true

--Global variable that contains all relevant server permission and other info
_G.servers = {}


_G.events = {}
_G.events["join"] = bit.arshift(1, 0)
_G.events["leave"] = bit.arshift(1, -1)

--Better debug thing, will redo in the future
local function ldebug(String)
	if not DEBUG then return end
	print(string.format("[%s]: %s", os.date("%c"), String))
end

--Announcements
local function announcement(Event, Member)
	local str = ""
	if Event == "join" then
		if bit.band(_G.servers[Member.server.id].data.msgsettings, _G.events.join) ~= 0 then
			str = _G.servers[Member.server.id].data.joinmsg
			str = string.gsub(str, "USERNAME", Member.name)
			str = string.gsub(str, "USERID", Member.id)
			str = string.gsub(str, "USERMENTION", Member:getMentionString())
			str = string.gsub(str, "NEWLINE", "\n")
		end
	elseif Event == "leave" then
		if bit.band(_G.servers[Member.server.id].data.msgsettings, _G.events.leave) ~= 0 then
			str = _G.servers[Member.server.id].data.joinmsg
			str = string.gsub(str, "USERNAME", Member.name)
			str = string.gsub(str, "USERID", Member.id)
			str = string.gsub(str, "USERMENTION", Member:getMentionString())
			str = string.gsub(str, "NEWLINE", "\n")
		end
	end
	if str == "" then return end
	Member.server:getChannelById(_G.servers[Member.server.id].data.msgchannel):sendMessage(str)
end
M.announcement = announcement

--Prints data found in path Message seperated by whitespaces.
local function printElement(String, Message)
	local str = string.gsub(String, "Server.id", Message.server.id)
	str = string.gsub(str, "Me.id", Message.author.id)
	local path = _G
	local returnstr = "```\n"
	for i in string.gmatch(str, "%S+") do
		if type(path[i]) ~= "nil" then
			path = path[i]
		else
			path = "Something went wrong; tried to index nil"
			break
		end
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

--Saves JSON file with permissions
local function savePermFile(Guild)
	ldebug("Running function "..debug.getinfo(1, "n").name)
	local file = io.open("./perms/perms_"..Guild.id..".json", "w")
	io.output(file)
	io.write(json.encode(_G.servers[Guild.id], { indent = true }))
	io.close(file)
end
M.savePermFile = savePermFile

--Sets values in the server specific data directory
local function setData(String, Message)
	local str = string.gsub(String, "Server.id", Message.server.id)
	str = string.gsub(str, "Me.id", Message.author.id)
	local key, value = string.match(str, "(%S+) (.*)")
	if key == nil then return end
	_G.servers[Message.server.id].data[key] = value
	savePermFile(Message.server)
end
M.setData = setData

--Checks if Char is one of the server's silent or loud character. This determines whether the command gets deleted
local function isSilent(Char, Guild)
	ldebug("Running function "..debug.getinfo(1, "n").name)
	if Char == _G.servers[Guild.id].data.silentchar then
		return true
	elseif Char == _G.servers[Guild.id].data.loudchar then
		return false
	else
		return nil
	end
end
M.isSilent = isSilent

--Checks Table for Id, if nothing is found, it defaults to Bool
local function checkForPerm(Table, Id, Bool)
	ldebug("Running function "..debug.getinfo(1, "n").name)
	local result = false
	if Table[Id] == true then
		result = true
	elseif Table[Id] == false then
		result = false
	else
		if Table[Id] == nil then
			ldebug("ERROR: Unexpected perm result: nil. Defaulting to "..tostring(Bool))
		end
		result = Bool
	end
	ldebug("Function "..debug.getinfo(1, "n").name.." returned: "..tostring(result))
	return result
end
M.defaultPerm = defaultPerm

--Function to check if file exists, used in other functions
local function fileExists(Name) --DONE
	ldebug("Running function "..debug.getinfo(1, "n").name)
   	local file = io.open(Name, "r")
   	if file ~= nil then io.close(file) return true else return false end
end
M.fileExists = fileExists

local function moduleExists(String)
	if MDATA.modules[String] then
		return true
	else
		return false
	end
end
M.moduleExists = moduleExists

local function loadModule(String, Guild)
	if not moduleExists(String) then return nil, "0:module doesn't exist" end
	for k, v in pairs(MDATA.modules[String].commands) do
		_G.servers[Guild.id].commands[k] = {}
		_G.servers[Guild.id].commands[k].roles =  {}
		_G.servers[Guild.id].commands[k].roles["placeholder"] = false
		if ROOT_ROLE ~= nil then
			_G.servers[Guild.id].commands[k].roles[ROOT_ROLE] = true
		end
		_G.servers[Guild.id].commands[k].channels = {}
		_G.servers[Guild.id].commands[k].channels["placeholder"] = false
		if ROOT_CHANNEL ~= nil then
			_G.servers[Guild.id].commands[k].roles[ROOT_CHANNEL] = true
		end
		_G.servers[Guild.id].commands[k].users = {}
		_G.servers[Guild.id].commands[k].users["placeholder"] = false
		_G.servers[Guild.id].commands[k].users[Guild.owner.id] = true
		if ROOT_USER ~= nil then
			_G.servers[Guild.id].commands[k].roles[ROOT_USER] = true
		end
	end
	savePermFile(Guild)
end
M.loadModule = loadModule

--Creates table structure and default entries for a server, used for instance when new server is detected
local function generatePermTable(Guild)
	ldebug("Running function "..debug.getinfo(1, "n").name)
	_G.servers[Guild.id] = {}
	_G.servers[Guild.id]["data"] = {}
	_G.servers[Guild.id].data["silentchar"] = "/"
	_G.servers[Guild.id].data["loudchar"] = "!"
	_G.servers[Guild.id].data["servername"] = Guild.name
	_G.servers[Guild.id].data["joinmsg"] = "User has joined the server"
	_G.servers[Guild.id].data["leavemsg"] = "User has left the server"
	_G.servers[Guild.id].data["msgchannel"] = Guild.defaultChannel.id
	_G.servers[Guild.id].data["msgsettings"] = 3
	_G.servers[Guild.id].data["modules"] = {
		base = true,
		debug = false
	}
	_G.servers[Guild.id]["commands"] = {}
	loadModule("base", Guild)
end
M.generatePermTable = generatePermTable

--Registers a new Command on a Server. Called when default command doesn't exist on a server
local function addCommand(Command, Guild)
	ldebug("Running function "..debug.getinfo(1, "n").name)
	_G.servers[Guild.id].commands[Command] = {}
	_G.servers[Guild.id].commands[Command].roles =  {}
	if ROOT_ROLE ~= nil then
		_G.servers[Guild.id].commands[Command].roles[ROOT_ROLE] = true
	end
	_G.servers[Guild.id].commands[Command].channels = {}
	if ROOT_CHANNEL ~= nil then
		_G.servers[Guild.id].commands[Command].channels[ROOT_CHANNEL] = true
	end
	_G.servers[Guild.id].commands[Command].users = {}
	if ROOT_USER ~= nil then
		_G.servers[Guild.id].commands[Command].users[ROOT_USER] = true
	end
	_G.servers[Guild.id].commands[Command].users[Guild.owner.id] = true
	savePermFile(Guild)
end
M.addCommand = addCommand

--Converts JSON with permissions for Server into table and loads it in the global table
local function loadPermFile(Guild)
	ldebug("Running function "..debug.getinfo(1, "n").name)
	local file = io.open("./perms/perms_"..Guild.id..".json", "r")
	io.input(file)
	local worked = false
	local obj, pos, err = json.decode(io.read("*a"), 1, nil)
	if err then
  		ldebug("Error:", err)
	else
		_G.servers[Guild.id] = obj
		worked = true
	end
	io.close(file)
	return worked
end
M.loadPermFile = loadPermFile

--Checks if Command exists on Server. If not, checks if Command is a default command, and if so, loads it
local function commandLoaded(Cmd, Guild)
	local returnval = false
	if _G.servers[Guild.id].commands[Cmd] then
		returnval = true
	else
		if commandExists(Cmd) then
			addCommand(Cmd, Guild)
			returnval = true
		else
			returnval = false
		end
	end
	ldebug("Running function "..debug.getinfo(1, "n").name..":"..tostring(returnval))
	return returnval
end
M.commandLoaded = commandLoaded

local function commandExists(Command)
	local found = false
	local moduleName = nil
	for mod, table in pairs(MDATA.modules) do
		if table.commands[Command] then
			found = true
			moduleName = mod
			break
		end
	end
	return found, moduleName
end
M.commandExists = commandExists


--Checks for permission JSON file for ALL servers, when server without file is found, generates server file with default commands
local function checkForPermFile(Client)
	ldebug("Running function "..debug.getinfo(1, "n").name)
	for Guild in Client.guilds do
		if not fileExists("./perms/perms_"..Guild.id..".json") then
			generatePermTable(Guild)
		else
			loadPermFile(Guild)
		end
	end
end
M.checkForPermFile = checkForPermFile

--Checks if the permissions are loaded in the global table for Server
local function isPermsLoaded(Guild) --DONE
	ldebug("Running function "..debug.getinfo(1, "n").name)
	if _G.servers[Guild.id] ~= nil then
		return true
	else
		return false
	end
end
M.isPermsLoaded = isPermsLoaded

--Takes two tables, and first cross checks the key. If match is found, the values are compared. If values also match,
--returns true or false (if found), and breaks. If values don't match, goes back to beginning. If nothing is found,
--return defaults to Bool
local function crossCheckKey(Function, Table2, Bool, Guild)
	local found = false
	local result = Bool
	for k, v in Function do
		if found then break end
		for kr, vr in pairs(Table2) do
			if kr == k then
				if vr == true then
					found = true
					result = true
					break
				elseif vr == false then
					found = true
					result = false
					break
				else
					ldebug("ERROR: Unexpected perm value: "..vr)
					found = true
				end
			end
		end
	end
	if Table2[Guild.defaultRole.id] == true then
		result = true
	elseif Table2[Guild.defaultRole.id] == false then
		result = false
	end
	ldebug("Function "..debug.getinfo(1, "n").name.." returned: "..tostring(result))
	return result
end
M.crossCheckKey = crossCheckKey

--Crosschecks the elements of two tables, returning true and ending when exact matches are found
local function crossCheckElement(Table, Table2) --READ ABOVE
	ldebug("Running function "..debug.getinfo(1, "n").name)
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
	return crossCheckKey(User.roles, _G.servers[User.guild.id].commands[Command].roles, false, User.guild)
end
M.roleAllowed = roleAllowed

--Checks if exception exists for the user and command, if nothing is found, defaults to nil
local function userAllowed(User, Command)
	return checkForPerm(_G.servers[User.guild.id].commands[Command].users, User.id, nil)
end
M.userAllowed = userAllowed

--Checks if the channel (gotten from Message.channel). allows the Command. If nothing is found, defaults to true
local function channelAllowed(Message, Command)
	return checkForPerm(_G.servers[Message.guild.id].commands[Command].channels, Message.channel.id, true)
end
M.channelAllowed = channelAllowed

--Combines the three above functions to get an absolute value. role and channel have to be true, and user, if
--existant, overrides everything. This means that user permissions are for fine tuning.
local function canUse(Message, Command)
	ldebug("Running function "..debug.getinfo(1, "n").name)
	local response = false
	if roleAllowed(Message.member, Command) then
		if channelAllowed(Message, Command) then
			response = true
		end
	end
	if userAllowed(Message.member, Command) ~= nil then
		response = userAllowed(Message.member, Command)
	end
	return response
end
M.canUse = canUse

--Changes permissions for everyone in the Table of mentions, depending on the Args. Returns string 'str' with
--info about the permission changes, formatted with backticks for discord
local function editPerms(Message, Args, Guild)
	ldebug("Running function "..debug.getinfo(1, "n").name)
	local action, commande = string.match(Args, "(%S+) (%S+)")
	if not commandExists(commande) then print("Command "..commande.." doesn't exist.") return end
	local str = "```\n"
	str = str.."Action "..action.." applied to command "..commande.." with members:\n"
	if action == "add" then
		action = true
	elseif action == "remove" then
		action = false
	elseif action == "clear" then
		action = nil
	end
	for user in Message.mentionedUsers do
		_G.servers[Guild.id].commands[commande].users[user.id] = action
		str = str..user.name.." ("..user.id..")\n"
	end
	str = str.."Channels:\n"
	for channel in Message.mentionedChannels do
		_G.servers[Guild.id].commands[commande].channels[channel.id] = action
		str = str..channel.name.." ("..channel.id..")\n"
	end
	str = str.."Roles:\n"
	for role in Message.mentionedRoles do
		_G.servers[Guild.id].commands[commande].roles[role.id] = action
		str = str..role.name.." ("..role.id..")\n"
	end
	savePermFile(Guild)
	str = str.."```"
	print(str)
	return str
end
M.editPerms = editPerms

--Returns a nicely formatted string with details on who can use a command
local function whoCanUse(Command, Guild, Client)
	print(Command)
	local str = "```\n"
	local allowed = ""
	if commandLoaded(Command, Guild) == false then return end
	str = str.."Members who can/cannot use command "..Command..":\n"
	if type(_G.servers[Guild.id].commands[Command].users) == "table" then
		for k, v in pairs(_G.servers[Guild.id].commands[Command].users) do
			if v ~= true and v ~= false then
				if v == true then
					allowed = "is allowed"
				else
					allowed = "is not allowed"
				end
				if Client:getMemberById(k) ~= nil then
					str = str..Client:getMemberById(k).name.." ("..k..") "..allowed.."\n"
				else
					ldebug("Invalid user ID found in "..Guild.name)
				end
			end
		end
	end
	str = str.."Channels that can/cannot use command "..Command..":\n"
	if type(_G.servers[Guild.id].commands[Command].channels) == "table" then
		for k, v in pairs(_G.servers[Guild.id].commands[Command].channels) do
			if v ~= true and v ~= false then
				if v == true then
					allowed = "is allowed"
				else
					allowed = "is not allowed"
				end
				if Client:getChannelById(k) ~= nil then
					str = str..Client:getChannelById(k).name.." ("..k..") "..allowed.."\n"
				else
					ldebug("Invalid channel ID found in "..Guild.name)
				end
			end
		end
	end
	str = str.."Roles that can/cannot use command "..Command..":\n"
	if type(_G.servers[Guild.id].commands[Command].roles) == "table" then
		for k, v in pairs(_G.servers[Guild.id].commands[Command].roles) do
			if v ~= true and v ~= false then
				if v == true then
					allowed = "is allowed"
				else
					allowed = "is not allowed"
				end
				if Client:getRoleById(k) ~= nil then
					str = str..Client:getRoleById(k).name.." ("..k..") "..allowed.."\n"
				else
					ldebug("Invalid role ID found in "..Guild.name)
				end
			end
		end
	end
	str = str.."```"
	return str
end
M.whoCanUse = whoCanUse

--Returns info associated with command
local function cmdinfo(Cmd)
	local returnval = "```\n"
	local found modName = commandExists(Cmd)
	if not found then
		returnval = nil
	elseif type(MDATA.modules[modName].commands[Cmd].info) ~= "string" then
		returnval = returnval.."This command has no info attached to it yet"
	else
		returnval = returnval..MDATA.modules[modName].commands[Cmd].info
	end
	returnval = returnval.."```"
	return returnval
end
M.cmdinfo = cmdinfo

--Returns usage associated with command
local function cmdusage(Cmd)
	local returnval = "```\n"
	local found, modName = commandExists(Cmd)
	if not found then
		returnval = nil
	elseif type(MDATA.modules[modName].commands[Cmd].usage) ~= "string" then
		returnval = returnval.."This command has no usage info attached to it yet"
	else
		returnval = returnval..MDATA.modules[modName].commands[Cmd].usage
	end
	returnval = returnval.."```"
	return returnval
end
M.cmdusage = cmdusage

--Returns info and usage associated with command
local function cmdhelp(Cmd)
	local returnval = ""
	if not commandExists(Cmd) then
		returnval = "```\nCommand '"..Cmd.."' doesn't exist.\n```"
	else
		returnval = returnval..cmdinfo(Cmd).."\n"
		returnval = returnval..cmdusage(Cmd)
	end
	return returnval
end
M.cmdhelp = cmdhelp

--Returns string with all commands with the server's loud character
local function listCommands(Guild)
	local str = "```\n"
	for k, v in pairs(_G.servers[Guild.id].data.modules) do
		if v then
			for command, _ in pairs(MDATA.modules[k].commands) do
				str = str.._G.servers[Guild.id].data.loudchar..command.."\n"
			end
		end
	end
	str = str.."```"
	return str
end
M.listCommands = listCommands



return M
