local discordia = require("discordia")
local client = discordia.Client()
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
	if type(arg) == "string" then
		larg = string.lower(arg)
	end
	local firstChar = string.sub(cmd, 1, 1)
	local delete = false
	cmd = string.lower(string.sub(cmd, 2))
	if perm.commandExists(cmd, message.guild) then
		if perm.canUse(message, cmd) then
			if perm.isSilent(firstChar, message.guild) ~= nil then
				delete = perm.isSilent(firstChar, message.guild)
				-------
				if cmd == "test" then
					message.channel:sendMessage("Test indeed")
				end
				-------
				if cmd == "permission" then
					message.channel:sendMessage(perm.editPerms(message, larg, message.guild))
				end
				-------
				if cmd == "whocanuse" then
					message.channel:sendMessage(perm.whoCanUse(larg, message.guild, client))
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
					-------
				elseif cmd == "info" then
					if arg == nil then return end
					message.channel:sendMessage(perm.cmdinfo(arg, message.guild))
					-------
				elseif cmd == "usage" then
					if arg == nil then return end
					message.channel:sendMessage(perm.cmdusage(arg, message.guild))
					-------
				elseif cmd == "help" then
					if larg then
						message.channel:sendMessage(perm.cmdhelp(arg, message.guild))
					else
						message.channel:sendMessage(perm.listCommands(message.guild))
					end
					-------
				end



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
