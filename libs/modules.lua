local M = {}
M.modules = {
	base = {
		commands = {
			info = {
				info = "A test command.",
				usage = "!test"
			},
			usage = {
			 	info = nil,
				usage = nil
			},
			help = {
				info = nil,
				usage = nil
			},
			permission = {
				info = "Used to add, remove or clear permissions.",
				usage = "!permission<add/remove/clear> <command name> <mentions (@user, @role, #channel)>\n\nAdding an user gives the user complete authority, even if their channel and role are blacklisted.\nSimilarly, blacklisting a user bans them entirely from using the command.\nFor a user to use a command, their role must allow it, and the channel must too.\n(if no specific rule is applied to the channel, it defaults to allowing the command)"
			},
			whocanuse = {
				info = nil,
				usage = nil
			},
			load = {
				info = nil,
				usage = nil
			},
			unload = {
				info = nil,
				usage = nil
			},
			listmodules = {
				info = nil,
				usage = nil
			}
		},
		version = 0.1
	},
	debug = {
		commands = {
			test = {
				info = "A test command.",
				usage = "!test"
			},
			printelement = {
				info = nil,
				usage = nil
			},
			setdata = {
				info = nil,
				usage = nil
			}
		},
		version = 0.1
	}
}

return M
