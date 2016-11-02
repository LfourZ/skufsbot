local http = require('coro-http')
local M = {}

dofile("./libs/xml.lua")
dofile("./libs/handler.lua")

local function xmlToTable(String)
  	local xmlhandler = simpleTreeHandler()
  	local xmlparser = xmlParser(xmlhandler)
  	xmlparser:parse(String)
  	return xmlhandler
end
M.xmlToTable = xmlToTable

local function httpXml(Url)
  	local res, data = http.request('GET', Url)
 	return xmlToTable(data)
end
M.httpXml = httpXml

return M