local M = {}

--A few requires
local ltable = require("./ltable") --For a few table functions
local httpfunctions = require("./httpFunctions") --For http functions and xml to table
local json = require("./json")

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
--TEMPLATE: _G.defcommands[""] = {info = nil, usage = nil}
_G.defcommands["test"] = {info = "A test command.", usage = "!test"}
_G.defcommands["permission"] = {info = "Used to add, remove or clear permissions", usage = "!permission<add/remove/clear> <command name> <mentions (@user, @role, #channel)>\n\nAdding an user gives the user complete authority, even if their channel and role are blacklisted.\nSimilarly, blacklisting a user bans them entirely from using the command.\nFor a user to use a command, their role must allow it, and the channel must too.\n(if no specific rule is applied to the channel, it defaults to allowing the command)"}
_G.defcommands["whocanuse"] = {info = "Tells you who can use specified command", usage = "!whocanuse <command name>"}
_G.defcommands["printelement"] = {info = "Prints specified element of permissions table", usage = "!printelement<path to element, layers seperated by whitespaces>\n\nYou can use Server.id and Me.id as placeholders for your id and the server's id"}
_G.defcommands["setdata"] = {info = "Sets any value in servers/serverID/data", usage = "!setdata <element> <value>\n\nYou can see the editable elements by running !printelement perms servers Server.id data\nWhile I was writing this, I noticed a bug: DON'T EDIT NUMBERS. Thanks"}
_G.defcommands["info"] = {info = "Gives brief description of command", usage = "!info <command>"}
_G.defcommands["usage"] = {info = "Shows usage of command", usage = "!usage <command>"}
_G.defcommands["help"] = {info = nil, usage = nil}



_G.events = {}
_G.events["join"] = bit.arshift(1, 0)
_G.events["leave"] = bit.arshift(1, -1)

local function ldebug(String)
	if not DEBUG then return end
	print(string.format("[%s]: %s", os.date("%c"), String))
end

local function announcement(Event, Member)
	local str = ""
	if Event == "join" then
		if bit.band(_G.perms.servers[Member.server.id].data.msgsettings, _G.events.join) ~= 0 then
			str = _G.perms.servers[Member.server.id].data.joinmsg
			str = string.gsub(str, "USERNAME", Member.name)
			str = string.gsub(str, "USERID", Member.id)
			str = string.gsub(str, "USERMENTION", Member:getMentionString())
			str = string.gsub(str, "NEWLINE", "\n")
		end
	elseif Event == "leave" then
		if bit.band(_G.perms.servers[Member.server.id].data.msgsettings, _G.events.leave) ~= 0 then
			str = _G.perms.servers[Member.server.id].data.joinmsg
			str = string.gsub(str, "USERNAME", Member.name)
			str = string.gsub(str, "USERID", Member.id)
			str = string.gsub(str, "USERMENTION", Member:getMentionString())
			str = string.gsub(str, "NEWLINE", "\n")
		end
	end
	if str == "" then return end
	Member.server:getChannelById(_G.perms.servers[Member.server.id].data.msgchannel):sendMessage(str)
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

--Initial test to use JSON
local function savePermFile(Server)
	ldebug("Running function "..debug.getinfo(1, "n").name)
	local file = io.open("./perms/perms_"..Server.id..".json", "w")
	io.output(file)
	io.write(json.encode(_G.perms.servers[Server.id], { indent = true }))
	io.close(file)
end
M.savePermFile = savePermFile

local function setData(String, Message)
	local str = string.gsub(String, "Server.id", Message.server.id)
	str = string.gsub(str, "Me.id", Message.author.id)
	local key, value = string.match(str, "(%S+) (.*)")
	if key == nil then return end

	_G.perms.servers[Message.server.id].data[key] = value
	savePermFile(Message.server)
end
M.setData = setData


--Checks if Char is one of the server's silent or loud character. This determines whether the command gets deleted
local function isSilent(Char, Guild)
	ldebug("Running function "..debug.getinfo(1, "n").name)
	if Char == _G.perms.servers[Guild.id].data.silentchar then
		return true
	elseif Char == _G.perms.servers[Guild.id].data.loudchar then
		return false
	else
		return nil
	end
end
M.isSilent = isSilent

--Checks Table for Id, if nothing is found, it defaults to Bool
local function checkForPerm(Table, Id, Bool) --DONE
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

--Creates table structure and default entries for a server, used for instance when new server is detected
local function generatePermTable(Server, Table) --I DUNNO
	ldebug("Running function "..debug.getinfo(1, "n").name)
	local tbl = {}
	tbl["data"] = {}
	tbl.data["silentchar"] = "/"
	tbl.data["loudchar"] = "!"
	tbl.data["servername"] = Server.name
	tbl.data["joinmsg"] = "User has joined the server"
	tbl.data["leavemsg"] = "User has left the server"
	tbl.data["msgchannel"] = Server.defaultChannel.id
	tbl.data["msgsettings"] = 3
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
	ldebug("Running function "..debug.getinfo(1, "n").name)
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

--Converts JSON with permissions for Server into table and loads it in the global table
local function loadPermFile(Server)

	ldebug("Running function "..debug.getinfo(1, "n").name)
	local file = io.open("./perms/perms_"..Server.id..".json", "r")
	io.input(file)
	local worked = false

	local obj, pos, err = json.decode(io.read("*a"), 1, nil)
	if err then
  		ldebug("Error:", err)
	else
		_G.perms.servers[Server.id] = obj
		worked = true
	end
	io.close(file)
	return worked
end
M.loadPermFile = loadPermFile

--Checks if Command exists on Server. If not, checks if Command is a default command, and if so, loads it
local function commandExists(Cmd, Guild)
	local returnval = false
	if type(_G.perms.servers[Guild.id].commands[Cmd]) ~= "nil" then
		returnval = true
	else
		if type(_G.defcommands[Cmd]) ~= "nil" then
			addCommand(Cmd, Guild)
			returnval = true
		else
			returnval = false
		end
	end
	ldebug("Running function "..debug.getinfo(1, "n").name..":"..tostring(returnval))
	return returnval
end
M.commandExists = commandExists

--Checks for permission JSON file for ALL servers, when server without file is found, generates server file with default commands
local function checkForPermFile(Client)
	ldebug("Running function "..debug.getinfo(1, "n").name)
	for Guild in Client.guilds do
		if not fileExists("./perms/perms_"..Guild.id..".json") then
			generatePermTable(Guild, _G.defcommands)
		else
			loadPermFile(Guild)
		end
	end
end
M.checkForPermFile = checkForPermFile

--Checks if the permissions are loaded in the global table for Server
local function isPermsLoaded(Server) --DONE
	ldebug("Running function "..debug.getinfo(1, "n").name)
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
local function crossCheckKey(Function, Table2, Bool, Server)
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
	if Table2[Server.defaultRole.id] == true then
		result = true
	elseif Table2[Server.defaultRole.id] == false then
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
	return crossCheckKey(User.roles, _G.perms.servers[User.guild.id].commands[Command].roles, false, User.guild)
end
M.roleAllowed = roleAllowed

--Checks if exception exists for the user and command, if nothing is found, defaults to nil
local function userAllowed(User, Command)
	return checkForPerm(_G.perms.servers[User.guild.id].commands[Command].users, User.id, nil)
end
M.userAllowed = userAllowed

--Checks if the channel (gotten from Message.channel). allows the Command. If nothing is found, defaults to true
local function channelAllowed(Message, Command)
	return checkForPerm(_G.perms.servers[Message.guild.id].commands[Command].channels, Message.channel.id, true)
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
	if not commandExists(commande, Guild) then print("Command "..commande.." doesn't exist.") return end
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
		_G.perms.servers[Guild.id].commands[commande].users[user.id] = action
		str = str..user.name.." ("..user.id..")\n"
	end
	str = str.."Channels:\n"
	for channel in Message.mentionedChannels do
		_G.perms.servers[Guild.id].commands[commande].channels[channel.id] = action
		str = str..channel.name.." ("..channel.id..")\n"
	end
	str = str.."Roles:\n"
	for role in Message.mentionedRoles do
		_G.perms.servers[Guild.id].commands[commande].roles[role.id] = action
		str = str..role.name.." ("..role.id..")\n"
	end
	savePermFile(Guild)
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
			if v ~= true and v ~= false then
				if v == true then
					allowed = "is allowed"
				else
					allowed = "is not allowed"
				end
				if Client:getMemberById(k) ~= nil then
					str = str..Client:getMemberById(k).name.." ("..k..") "..allowed.."\n"
				else
					ldebug("Invalid user ID found in "..Server.name)
				end
			end
		end
	end
	str = str.."Channels that can/cannot use command "..Command..":\n"
	if type(_G.perms.servers[Server.id].commands[Command].channels) == "table" then
		for k, v in pairs(_G.perms.servers[Server.id].commands[Command].channels) do
			if v ~= true and v ~= false then
				if v == true then
					allowed = "is allowed"
				else
					allowed = "is not allowed"
				end
				if Client:getChannelById(k) ~= nil then
					str = str..Client:getChannelById(k).name.." ("..k..") "..allowed.."\n"
				else
					ldebug("Invalid channel ID found in "..Server.name)
				end
			end
		end
	end
	str = str.."Roles that can/cannot use command "..Command..":\n"
	if type(_G.perms.servers[Server.id].commands[Command].roles) == "table" then
		for k, v in pairs(_G.perms.servers[Server.id].commands[Command].roles) do
			if v ~= true and v ~= false then
				if v == true then
					allowed = "is allowed"
				else
					allowed = "is not allowed"
				end
				if Client:getRoleById(k) ~= nil then
					str = str..Client:getRoleById(k).name.." ("..k..") "..allowed.."\n"
				else
					ldebug("Invalid role ID found in "..Server.name)
				end
			end
		end
	end
	str = str.."```"
	return str
end
M.whoCanUse = whoCanUse

local function cmdinfo(Cmd, Server)
	local returnval = "```\n"
	if not commandExists(Cmd, Server) then
		returnval = nil
	elseif type(_G.defcommands[Cmd].info) ~= "string" then
		returnval = returnval.."This command has no info attached to it yet"
	else
		returnval = returnval.._G.defcommands[Cmd].info
	end
	returnval = returnval.."```"
	return returnval
end
M.cmdinfo = cmdinfo

local function cmdusage(Cmd, Guild)
	local returnval = "```\n"
	if not commandExists(Cmd, Guild) then
		returnval = nil
	elseif type(_G.defcommands[Cmd].usage) ~= "string" then
		returnval = returnval.."This command has no usage info attached to it yet"
	else
		returnval = returnval.._G.defcommands[Cmd].usage
	end
	returnval = returnval.."```"
	return returnval
end
M.cmdusage = cmdusage

local function cmdhelp(Cmd, Server)
	local returnval = ""
	if Cmd == nil then
		returnval = "```Commandlist not yet implemented```"
	else
		if not commandExists(Cmd, Server) then
			returnval = "```\nCommand '"..Cmd.."' doesn't exist.\n```"
		else
			returnval = returnval..cmdinfo(Cmd, Server).."\n"
			returnval = returnval..cmdusage(Cmd, Server)
		end
	end
	return returnval
end
M.cmdhelp = cmdhelp


return M
