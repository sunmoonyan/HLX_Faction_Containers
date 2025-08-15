-- Propriété container faction pour gérer l'accès faction/classe
local container = ix.plugin.list["containers"]

properties.Add("container_faction", {
    MenuLabel = "Faction Equippement",
    Order = 400,
    MenuIcon = "icon16/group_gear.png",

    Filter = function(self, entity, client)
        if entity:GetClass() ~= "ix_container" then return false end
        if not gamemode.Call("CanProperty", client, "container_faction", entity) then return false end
        return true
    end,

    Action = function(self, entity)
        Derma_StringRequest("Faction Equipement", [[
Type here which factions / classes can open this storage to take their equipment
---------------------------------------------------|Format|---------------------------------------------------
faction1,faction2,faction3/classe1,classe2,classe3 
---------------------------------------------------|Example|--------------------------------------------------
police,medic/officier,doctor
]],
        "", function(text)
            local factionStr, classStr = text:match("^(.-)%s*/%s*(.-)$")

            local factions = {}
            local classes = {}

            if factionStr then
                -- Cas avec slash : factions et classes
                for word in string.gmatch(factionStr, '([^,]+)') do
                    word = word:match("^%s*(.-)%s*$")  -- trim espaces
                    table.insert(factions, string.lower(word))
                end
                if classStr then
                    for word in string.gmatch(classStr, '([^,]+)') do
                        word = word:match("^%s*(.-)%s*$")
                        table.insert(classes, string.lower(word))
                    end
                end
            else
                -- Pas de slash : tout dans factions
                for word in string.gmatch(text, '([^,]+)') do
                    word = word:match("^%s*(.-)%s*$")
                    table.insert(factions, string.lower(word))
                end
            end

            self:MsgStart()
                net.WriteEntity(entity)
                net.WriteTable(factions)
                net.WriteTable(classes)
            self:MsgEnd()
        end)
    end,

    Receive = function(self, length, client)
        local entity = net.ReadEntity()
        local factions = net.ReadTable()
        local classes = net.ReadTable()
        if not IsValid(entity) then return end
        if not self:Filter(entity, client) then return end

        local inv = entity:GetInventory()

        if table.IsEmpty(factions) then
            inv["factionstorage"] = false
            for _, v in pairs(inv:GetItems(true)) do
                if v:GetData("factionitem") then
                    ix.inventory.Get(v["invID"]):Remove(v["id"])
                end
            end
        else
            inv["factionstorage"] = true
            inv["factionstorage_factions"] = factions
            inv["factionstorage_classes"] = classes
        end
        container:SaveContainer()
    end
})

