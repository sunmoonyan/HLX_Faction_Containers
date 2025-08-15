--[[
 ________  ___  ___  ________   ________  ___  ___  ___     
|\   ____\|\  \|\  \|\   ___  \|\   ____\|\  \|\  \|\  \    
\ \  \___|\ \  \\\  \ \  \\ \  \ \  \___|\ \  \\\  \ \  \   
 \ \_____  \ \  \\\  \ \  \\ \  \ \_____  \ \   __  \ \  \  
  \|____|\  \ \  \\\  \ \  \\ \  \|____|\  \ \  \ \  \ \  \ 
    ____\_\  \ \_______\ \__\\ \__\____\_\  \ \__\ \__\ \__\
   |\_________\|_______|\|__| \|__|\_________\|__|\|__|\|__|
   \|_________|                   \|_________|              
]]--

local PLUGIN = PLUGIN

PLUGIN.name = "Faction Containers"
PLUGIN.author = "Sunshi"
PLUGIN.description = "Add possibility to containers to give items for a player in a faction."
PLUGIN.requires = {"containers"}




if SERVER then
    Faction_Containers_DB = Faction_Containers_DB or {}

    function PLUGIN:LoadData()
        for i,v in ipairs(self.requires) do
            if ix.plugin.list[v] == nil then 
                --HLXRP_PluginRequirement(string.upper(v))
            end
        end
        Faction_Containers_DB = self:GetData()
        self:LoadContainer()
    end

    include("faction_containers/sv_faction_containers.lua")
    include("faction_containers/sh_faction_containers.lua")
    AddCSLuaFile("faction_containers/cl_faction_containers.lua")
    AddCSLuaFile("faction_containers/sh_faction_containers.lua")    

else 
    include("faction_containers/cl_faction_containers.lua")
    include("faction_containers/sh_faction_containers.lua")
end
