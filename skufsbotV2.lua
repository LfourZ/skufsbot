local discordia = require("discordia")
local client = discordia.Client:new()
local token = require("../token")
local perm = require("./libs/perm")
local httpfn = require("./libs/httpFunctions")


client:on("ready", function()
	p(string.format("Logged in as %s", client.user.username))
	perm.checkForPermFile(client)
end)

client:on("messageCreate", function(message)
	if message.author == client.user then return end
	local cmd, arg = string.match(message.content, "(%S+) (.*)")
	cmd = cmd or message.content
	local larg = nil
	if arg ~= nil then
		larg = string.lower(arg)
	end

	local firstChar = string.sub(cmd, 1, 1)
	local delete = false
	cmd = string.lower(string.sub(cmd, 2))


	if perm.commandExists(cmd, message.server) then
		if perm.canUse(message, cmd) then
			if perm.isSilent(firstChar, message.server) ~= nil then
				delete = perm.isSilent(firstChar, message.server)
				-------
				if cmd == "test" then
					message.channel:sendMessage("Test indeed")
				end
				-------
				if cmd == "permission" then
					message.channel:sendMessage(perm.editPerms(message.mentions, larg, message.server))
				end
				-------
				if cmd == "whocanuse" then
					message.channel:sendMessage(perm.whoCanUse(larg, message.server, client))
				end
				-------
				if cmd == "printelement" then
					if arg == nil then return end
					message.channel:sendMessage(perm.printElement(arg, message))
				end
				-------
				if cmd == "setdata" then
					if arg == nil then return end
					perm.setData(arg, message)
				end
				-------
				
				--Put commands here

				
				if delete then
					message:delete()
				end
			end
		end
	end
end)

client:on("memberJoin", function(member)
	perm.announcement("join", member)
end)


client:on("memberLeave", function(member)
	perm.announcement("leave", member)
end)

client:run(_G.SKUFS_TOKEN)