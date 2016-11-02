local discordia = require("discordia")
local token = require("../token")
local client = discordia.Client:new()
local http = require('coro-http')
local httpfunctions = require("./libs/httpFunctions")
local log = require("./libs/log")
local ltable = require("./libs/ltable")
local SILENT_CHAR = "/"
local LOUD_CHAR = "!"
local COOLDOWN = 10
local disable = false
local LOG_SERVER_CHAT = "239426562565472277"
local LOG_CHANNEL_CHAT = "239682857092513792"

local LOG_SERVER_ADMIN = "239426562565472277"
local LOG_CHANNEL_ADMIN = "239682857092513792"

local cooldowns = {}

local ip = {}
ip["bigcity"] = "130.240.202.21:27015"
ip["bc"] = "130.240.202.21:27015"
ip["city"] = "130.240.202.21:27015"
ip["pokemon"] = "130.240.202.21:27016"
ip["poke"] = "130.240.202.21:27016"
ip["surf"] = "130.240.202.21:27017"
ip["mariokart"] = "130.240.202.21:27018"
ip["mario"] = "130.240.202.21:27018"
ip["mk"] = "130.240.202.21:27018"

local serverName = {}
serverName["130.240.202.21:27015"] = "Bigcity"
serverName["130.240.202.21:27016"] = "Pokemon"
serverName["130.240.202.21:27017"] = "Surf"
serverName["130.240.202.21:27018"] = "MarioKart"

local channels = {}
channels["212548102660423681"] =  true

local running = false


client:on("ready", function()
	p("------------------------------------------------------------------------")
	p(string.format("%s: Logged in as %s.", os.date("%c"), client.user.username))
end)

client:on("messageDelete", function(message)
	if disable then return end
	if message.author == client.user then return end
	if message.server.id == "212548102660423681" then
		local logstr = os.date("%c:Message by'")..message.author.name.."' ("..message.author.id..") was deleted. Content: '"..message.content.."' In channel "..message.channel.name.." ("..message.channel.id..")"
		log.logChat(client, logstr, LOG_SERVER_CHAT, LOG_CHANNEL_CHAT)
		log.logChat(client, logstr, LOG_SERVER_ADMIN, LOG_CHANNEL_ADMIN)
	end
end)

client:on("memberUnban", function(member)
	if member.server.id == "212548102660423681" then
		local logstr = os.date("%c:Member '")..message.author.name.."' ("..message.author.id..") was banned"
		log.logChat(client, logstr, LOG_SERVER_ADMIN, LOG_CHANNEL_ADMIN)
	end
end)

client:on("messageCreate", function(message)
	if disable then return end
	if running then return end
	if message.author == client.user then return end
	if message.server.id == "212548102660423681" then
		local logstr = os.date("%c:'")..message.author.name.."' ("..message.author.id..") said: '"..message.content.."' In channel "..message.channel.name.." ("..message.channel.id..")"
		log.logChat(client, logstr, LOG_SERVER_CHAT, LOG_CHANNEL_CHAT)
	end


	local cmd, arg = string.match(message.content, "(%S+) (.*)")
	cmd = cmd or message.content
	local firstchar = string.sub(cmd, 1, 1)
	if firstchar ~= SILENT_CHAR and firstchar ~= LOUD_CHAR then return end
	cmd = string.sub(cmd, 2)
	local delete = false
	if firstchar == SILENT_CHAR then
		delete = true
	end

	if message.author.id == "124243691123638274" and cmd == "!disable" then disable = true end
	if message.server.id == "212548102660423681" then
		if not channels[message.channel.id] then return end
	end

	if arg then argl = string.lower(arg) end
	if ltable.numKeys(message.author.roles) > 0 then
		if cooldowns[message.author.id] ~= nil and cooldowns[message.author.id] < os.clock() then
			message:delete()
			return end
		if cmd == "playerlist" or cmd == "players" or cmd == "online" then
			running = true
			if arg == nil then running = false return end
			if ip[argl] == nil then running = false return end
			local xml = httpfunctions.httpXml("http://stats.skufs.net/api/serverinfo/"..ip[argl].."/players")
			local msg = ""
			if xml.root.gameME.serverinfo.server.act == "0" then
				msg = "```There are currently no players on "..serverName[ip[argl]].."```"
			else
				msg = "```\nThere are currently "..xml.root.gameME.serverinfo.server.act.." players online on the "..serverName[ip[argl]].." server:\n"
				for k, v in pairs(xml.root.gameME.serverinfo.server.players.player) do
					msg = msg..v.name.."\n"
				end
				msg = msg.."```"
			end
			message.channel:sendMessage(msg)
			cooldowns[message.author.id] = os.clock() + COOLDOWN
			if delete then
				message:delete()
			end
			running = false
		end
	end
end)

client:run(_G.SKUFS_TOKEN)