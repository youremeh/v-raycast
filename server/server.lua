RegisterCommand(Config.Command, function(source, args, rawCommand)
    local playerId = GetPlayerIdentifier(source, 0)
    if Config.UsePermissions then
        if playerId and IsPlayerAdmin(playerId) then TriggerClientEvent('v-raycast:client:toggle', source) end
    else
        TriggerClientEvent('v-raycast:client:toggle', source)
    end
end, false)

function IsPlayerAdmin(playerId)
    for _, admin in ipairs(Config.Permission) do
        if playerId == admin then return true end
    end
    return false
end