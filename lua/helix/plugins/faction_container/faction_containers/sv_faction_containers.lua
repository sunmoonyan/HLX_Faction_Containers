if SERVER then
    local container = ix.plugin.list["containers"]
    Faction_Containers_DB["faction_container"] = Faction_Containers_DB["faction_container"] or {}
local character = ix.meta.character


function PLUGIN:PlayerJoinedClass(client, class, oldClass)
    local char = client:GetCharacter()
    local charInv = char:GetInventory()
        for _, v in pairs(charInv:GetItems()) do
            if v:GetData("factionitem") then
                v:Remove()
            end
        end
end

hook.Add("OnCharacterTransferred", "RemoveFactionItems", function(self, faction)
    local charInv = self:GetInventory()
        for _, v in pairs(charInv:GetItems()) do
            if v:GetData("factionitem") then
                v:Remove()
            end
        end
end)



hook.Add( "EntityTakeDamage", "ForceLeaveContainer", function( target, dmginfo )
        if target:IsPlayer() then
        local client = target
        local inventory = client.ixOpenStorage
        if (inventory) then
        net.Start("ixStorageExpired")
        net.Send(client)
        ix.storage.RemoveReceiver(client, inventory)
        end
    end
end )

    function PLUGIN:LoadContainer()
        if Faction_Containers_DB["faction_container"] then
            for _, v in ipairs(Faction_Containers_DB["faction_container"]) do
                local data2 = ix.container.stored[v[4]:lower()]
                if not data2 then continue end

                local inventoryID = tonumber(v[3])
                if not inventoryID or inventoryID < 1 then
                    ErrorNoHalt(string.format(
                        "[Helix] Attempted to restore container inventory with invalid inventory ID '%s' (%s, %s)\n",
                        tostring(inventoryID), v[6] or "no name", v[4] or "no model"))
                    continue
                end

                local entity = ents.Create("ix_container")
                entity:SetPos(v[1])
                entity:SetAngles(v[2])
                entity:Spawn()
                entity:SetModel(v[4])
                entity:SetSolid(SOLID_VPHYSICS)
                entity:PhysicsInit(SOLID_VPHYSICS)

                if v[5] then
                    entity.password = v[5]
                    entity:SetLocked(true)
                    entity.Sessions = {}
                    entity.PasswordAttempts = {}
                end

                if v[6] then
                    entity:SetDisplayName(v[6])
                end

                if v[7] then
                    entity:SetMoney(v[7])
                end

                ix.inventory.Restore(inventoryID, data2.width, data2.height, function(inventory)
                    inventory.vars.isBag = true
                    inventory.vars.isContainer = true

                    if IsValid(entity) then
                        entity:SetInventory(inventory)
                    end

                    if v[8] then
                        inventory["factionstorage"] = v[8]
                    end
                    if v[9] then
                        inventory["factionstorage_factions"] = v[9]
                    end
                    if v[10] then
                        inventory["factionstorage_classes"] = v[10]
                    end
                end)

                local physObject = entity:GetPhysicsObject()
                if IsValid(physObject) then
                    physObject:EnableMotion()
                end
            end
        end
    end


    function container:SaveContainer()
        local data = {}
        Faction_Containers_DB["faction_container"] = {}
        for _, v in ipairs(ents.FindByClass("ix_container")) do
            if hook.Run("CanSaveContainer", v, v:GetInventory()) ~= false then
                local inventory = v:GetInventory()
                if inventory then
                    if not inventory["factionstorage"] then
                        data[#data + 1] = {
                            v:GetPos(),
                            v:GetAngles(),
                            inventory:GetID(),
                            v:GetModel(),
                            v.password,
                            v:GetDisplayName(),
                            v:GetMoney()
                        }
                    else
                        Faction_Containers_DB["faction_container"][#Faction_Containers_DB["faction_container"] + 1] = {
                            v:GetPos(),
                            v:GetAngles(),
                            inventory:GetID(),
                            v:GetModel(),
                            v.password,
                            v:GetDisplayName(),
                            v:GetMoney(),
                            inventory["factionstorage"],
                            inventory["factionstorage_factions"],
                            inventory["factionstorage_classes"],
                        }
                    end
                end
            else
                local index = v:GetID()

                local query = mysql:Delete("ix_items")
                query:Where("inventory_id", index)
                query:Execute()

                query = mysql:Delete("ix_inventories")
                query:Where("inventory_id", index)
                query:Execute()
            end
        end

        ix.plugin.list["faction_container"]:SetData(Faction_Containers_DB)
        self:SetData(data)
    end

    function PLUGIN:CanPlayerDropItem(client, item)
        local itemb = ix.item.instances[item]
 
        if itemb and itemb:GetData("factionitem") then
            return false,ix.util.NotifyLocalized("cantdropfactionitem",client)
        end
    end

    function PLUGIN:CanPlayerCombineItem(client, item, other)
        local itemb = ix.item.instances[item]

        if itemb and itemb:GetData("factionitem") then
            return false
        end
    end

    function PLUGIN:CanTransferItem(item, currentInv, oldInv)
        -- Bloque transfert depuis un factionstorage vers un inventaire de joueur,
        -- sauf si l'item est un jobitem et vient de factionstorage
        if oldInv["factionstorage"] and currentInv["owner"] ~= nil then
            if not (item:GetData("factionitem") and oldInv["factionstorage"]) then
                return false
            end
        end

        -- Bloque transfert d'un jobitem vers un inventaire joueur,
        -- sauf s'il vient de factionstorage
        if item:GetData("factionitem") and currentInv["owner"] ~= nil then
            if not oldInv["factionstorage"] then
                return false
            end
        end
    end




    hook.Add("CanAccessContainer", "FactionCanAccess", function(client, inventory, info)

        local char = client:GetCharacter()
        local charFaction = string.lower(ix.faction.Get(client:Team()).name)

        local charClass = nil
        if char:GetClass() then 
            charClass = string.lower(ix.class.Get(char:GetClass()).name) 
        end

        local isInvFaction = false
        local isInvClasses = false

        -- Vérification factions
        if istable(inventory["factionstorage_factions"]) and next(inventory["factionstorage_factions"]) ~= nil then
            for _, v in pairs(inventory["factionstorage_factions"]) do
                if v == charFaction then
                    isInvFaction = true
                    break
                end
            end

            if not isInvFaction then
                ix.util.NotifyLocalized("cantaccess",client)
                return false
            end
        end

        -- Vérification classes
        if istable(inventory["factionstorage_classes"]) and next(inventory["factionstorage_classes"]) ~= {} and !table.IsEmpty(inventory["factionstorage_classes"]) then
            for _, v in pairs(inventory["factionstorage_classes"]) do
                if v == charClass then
                    isInvClasses = true
                    break
                end
            end

            if not isInvClasses then
                ix.util.NotifyLocalized("cantaccess",client)
                return false
            end
        end

    end)


hook.Add("OnContainerOpened", "DebugContainerOpen", function(client, inventory, info)
    if inventory["factionstorage"] == true then
        local char = client:GetCharacter()
        if not char then 
            return 
        end

        local charInv = char:GetInventory()
        local items = {}
        local faction = ix.faction.Get(client:Team())
        local charFaction = faction and string.lower(faction.name) or "unknown"

        -- Vide le conteneur
        for _, item in pairs(inventory:GetItems()) do
            item:Remove()
        end

        -- Liste des items actuels du joueur
        for _, v in pairs(charInv:GetItems()) do
            if v:GetData("factionitem") then
                table.insert(items, v.uniqueID)
            end
        end

        -- Fusion faction.items + class.items
        local combinedItems = {}

        for _, v in ipairs(faction.items or {}) do
            table.insert(combinedItems, v)
        end

        local charClass = char:GetClass()
        if charClass then 
            local classData = ix.class.Get(charClass)
            for _, v in ipairs(classData and classData.items or {}) do
                table.insert(combinedItems, v)
            end
        end

        -- Ajoute les manquants dans le conteneur
        for _, v in ipairs(combinedItems) do
            local hasItem = false

            for i, item in ipairs(items) do
                if item == v then
                    table.remove(items, i)
                    hasItem = true
                    break
                end
            end

            if not hasItem then
                inventory:Add(v)
            end
        end

        -- Marque tout en jobitem
        for _, v in pairs(inventory:GetItems()) do
            v:SetData("factionitem", true)
        end
    end
end)


    hook.Add("OnContainerClosed", "DebugContainerClose", function(client, inventory, info)
        if inventory["factionstorage"] == true then
            for _, item in pairs(inventory:GetItems()) do
                item:Remove()
            end
        end
    end)
end