fx_version 'cerulean'
game 'gta5'

author 'V-Scripts https://discord.gg/M9fXSG7wa8'
description 'Get entity data from a raycast.'
version '1.0.0'
lua54 "yes"

shared_script {
    '@ox_lib/init.lua',
    'config.lua'
}

client_script {
    'client/*.lua'
}

server_script {
    'server/*.lua'
}