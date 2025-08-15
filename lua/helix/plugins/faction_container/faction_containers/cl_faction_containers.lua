if CLIENT then
    hook.Add("InitializedPlugins", "AddGlobalPaintOver", function()
        for _, itemTable in pairs(ix.item.list) do
            local oldPaintOver = itemTable.PaintOver

            itemTable.PaintOver = function(self, item, w, h)
                local isfactionitem = false

                if istable(item) and isfunction(item.GetData) then
                    isfactionitem = item:GetData("factionitem", false)
                end

                if oldPaintOver then
                    oldPaintOver(self, item, w, h)
                end

                if isfactionitem then
                    surface.SetDrawColor(110, 110, 255, 100)
                    surface.DrawRect(w - 14, h - 14, 8, 8)

                end
            end
        end
    end)
end
