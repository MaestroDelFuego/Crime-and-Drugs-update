fx_version 'cerulean'
game 'gta5'

description 'Gun Van - Fixed Location Black Market (No Alerts)'
author 'MaestroDelFuego'
version '1.0.0'

client_scripts {
    'client.lua'
}

server_scripts {
    '@qb-core/server/main.lua',
    'server.lua'
}

shared_script '@qb-core/shared/locale.lua'
