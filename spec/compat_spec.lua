local wow = require("spec.helpers.wow")

for _, client in ipairs(wow.clients) do
    describe("Compat on " .. client.name, function()
        local game, Compat

        before_each(function()
            game = wow.load(client)
            Compat = game.ns.Compat
        end)

        it("finds the client's action slot count", function()
            assert.are.equal(client.maxSlots, Compat.MaxActionSlots)
        end)

        it("picks up spells and items with whichever API the client has", function()
            game.spells[100] = "Charge"
            game.items[6948] = "Hearthstone"

            Compat.PickupSpell(100)
            assert.are.same({ type = "spell", id = 100 }, game.cursor)

            Compat.PickupItem(6948)
            assert.are.same({ type = "item", id = 6948 }, game.cursor)
        end)

        it("gets spell names with whichever API the client has", function()
            game.spells[100] = "Charge"

            assert.are.equal("Charge", Compat.GetSpellName(100))
            assert.is_nil(Compat.GetSpellName(999))
        end)

        it("picks up equipment sets by name", function()
            game.equipmentSets[3] = "Tank"

            Compat.PickupEquipmentSet("Tank")
            assert.are.same({ type = "equipmentset", id = "Tank" }, game.cursor)
        end)

        it("leaves the cursor empty for an equipment set that no longer exists", function()
            Compat.PickupEquipmentSet("Deleted")
            assert.is_nil(game.cursor)
        end)
    end)
end
