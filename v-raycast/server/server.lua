local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Commands.Add(Config.Command, "Enable raycast coords (God Only)", {}, false, function(source, args)
    TriggerClientEvent('v-raycast:client:toggle', source)
end, Config.Permissions)