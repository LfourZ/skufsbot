local discordia = require("discordia")
local M = {}

local function logChat(Client, String, ServerID, ChannelID)
	Client:getServerById(ServerID):getChannelById(ChannelID):sendMessage(String)
end
M.logChat = logChat

return M

