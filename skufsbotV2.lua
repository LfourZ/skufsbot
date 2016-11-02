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
					local testy = perm.editPerms(message.mentions, larg, message.server)
					message.channel:sendMessage(testy)
				end
				-------
				if cmd == "whocanuse" then
					message.channel:sendMessage(perm.whoCanUse(larg, message.server, client))
				end


				--Put commands here

				
				if delete then
					message:delete()
				end
			end
		end
	end
end)

client:run(_G.SKUFS_TOKEN)