Config = {}

Config.Command = 'raycast' -- Command used to start raycast

 -- Permssion to use command
Config.UsePermissions = true
Config.Permission = {
    "steam:123456789012345",  -- Replace with actual Steam IDs or other identifiers of admins
    "license:abcdef123456",   -- Another identifier example
    -- Add more
}

Config.BoxColor = {r = 255, g = 255, b = 255, a = 255} -- Color of the box

Config.LineColor =  {r = 255, g = 255, b = 255, a = 200} -- Color of the line
Config.HighlightedLineColor = {r = 0, g = 191, b = 255, a = 200} -- Color of the line when raycasted on an entity
