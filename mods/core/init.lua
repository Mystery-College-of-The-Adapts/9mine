local path = minetest.get_modpath("core")
dofile(path .. "/modload.lua")

core_conf = Settings(path .. "/mod.conf")

-- global values
connections = {}

-- libraries 
require "socket"
require "class"
require 'readdir'
require 'md5'
require 'connection'
require 'cmdchan'

np = require '9p'

-- mod files 
require 'on_join.inventory'
require 'tools.connect'
require 'events.events'
require 'events.connect'