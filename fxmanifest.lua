fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'httphandler'
author 'ricepunk'
version '1.0.0'
license 'LGPL-3.0'
repository 'https://github.com/ricepunk/httphandler'
description 'A straightforward and efficient REST API designed to handle basic CRUD operations with minimal setup.'

dependency 'ox_lib'
shared_script '@ox_lib/init.lua'
server_script 'server/example.lua'
