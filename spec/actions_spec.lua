local wow = require("spec.helpers.wow")

-- Drives the addon through /abs, the same way a player does
for _, client in ipairs(wow.clients) do
    describe("/abs on " .. client.name, function()
        local game

        before_each(function()
            game = wow.load(client)
            game.spells[100] = "Charge"
            game.spells[20549] = "War Stomp"
            game.items[6948] = "Hearthstone"
            game.macros[1] = "Heal"
            game.equipmentSets[0] = "Tank"
        end)

        local function sets() return game.db.class.sets end

        describe("save and restore", function()
            it("restores spells, items, macros and equipment sets to their slots", function()
                game.bar[1] = { type = "spell", id = 100 }
                game.bar[2] = { type = "item", id = 6948 }
                game.bar[3] = { type = "macro", id = 1 }
                game.bar[4] = { type = "equipmentset", id = "Tank" }
                game.bar[client.maxSlots] = { type = "spell", id = 20549 }

                game:slash("save test")
                game:clearBar()
                game:slash("restore test")

                assert.are.same({
                    [1] = { type = "spell", id = 100 },
                    [2] = { type = "item", id = 6948 },
                    [3] = { type = "macro", id = 1 },
                    [4] = { type = "equipmentset", id = "Tank" },
                    [client.maxSlots] = { type = "spell", id = 20549 },
                }, game.bar)
                assert.is_nil(game.cursor)
                assert.are.same({ "Saved set 'test'!", "Restored set 'test'" }, game:messages())
            end)

            if client.mountJournal then
                it("restores mounts, wherever they sit in the mount journal", function()
                    game.mounts = { 3128, 3130 }
                    game.bar[36] = { type = "summonmount", id = 3130 }
                    game.bar[37] = { type = "summonmount", id = 268435455 }
                    game:slash("save test")

                    game.mounts = { 3130, 3128 }
                    game:clearBar()
                    game:slash("restore test")

                    assert.are.same({ type = "summonmount", id = 3130 }, game.bar[36])
                    assert.are.same({ type = "summonmount", id = 268435455 }, game.bar[37])
                    assert.are.same({ "Saved set 'test'!", "Restored set 'test'" }, game:messages())
                end)
            end

            if client.transmogOutfits then
                it("restores transmog outfits", function()
                    game.outfits = { [2] = "Raid", [3] = "Town" }
                    game.bar[26] = { type = "outfit", id = 2 }
                    game.bar[27] = { type = "outfit", id = 3 }
                    game:slash("save test")

                    game:clearBar()
                    game:slash("restore test")

                    assert.are.same({ type = "outfit", id = 2 }, game.bar[26])
                    assert.are.same({ type = "outfit", id = 3 }, game.bar[27])
                    assert.are.same({ "Saved set 'test'!", "Restored set 'test'" }, game:messages())
                end)
            end

            it("saves macros by name, so they survive being reordered", function()
                game.bar[1] = { type = "macro", id = 1 }
                game:slash("save test")

                game.macros = { [5] = "Heal" }
                game:clearBar()
                game:slash("restore test")

                assert.are.same({ type = "macro", id = 5 }, game.bar[1])
            end)

            it("restores macros that show a spell or an item", function()
                game.macros[2] = "Opener"
                game.macroContents[2] = { type = "spell", id = 100 }
                game.macros[3] = "Trinket"
                game.macroContents[3] = { type = "item", id = 6948 }
                game.bar[1] = { type = "macro", id = 2 }
                game.bar[2] = { type = "macro", id = 3 }

                game:slash("save test")
                game:clearBar()
                game:slash("restore test")

                assert.are.same({
                    [1] = { type = "macro", id = 2 },
                    [2] = { type = "macro", id = 3 },
                }, game.bar)
            end)

            it("saves only slots that have an action", function()
                game.bar[7] = { type = "spell", id = 100 }

                game:slash("save test")

                assert.are.same({ [7] = { type = "spell", id = 100 } }, sets().test)
            end)

            it("clears slots that were empty when the set was saved", function()
                game:slash("save empty")
                game.bar[1] = { type = "spell", id = 100 }

                game:slash("restore empty")

                assert.are.same({}, game.bar)
            end)

            it("reports actions it can't restore and keeps going", function()
                game.bar[1] = { type = "spell", id = 100 }
                game.bar[2] = { type = "item", id = 6948 }
                game:slash("save test")

                game.spells[100] = nil
                game:clearBar()
                game:clearOutput()
                game:slash("restore test")

                assert.are.same({ [2] = { type = "item", id = 6948 } }, game.bar)
                assert.are.same({
                    "Restored set 'test'",
                    "Error: Unable to restore spell with id [100] to slot 1",
                }, game:messages())
            end)

            it("refuses to restore in combat", function()
                game.bar[1] = { type = "spell", id = 100 }
                game:slash("save test")
                game:clearBar()
                game:clearOutput()

                game.inCombat = true
                game:slash("restore test")

                assert.are.same({}, game.bar)
                assert.are.same({ "Cannot restore sets while in combat" }, game:messages())
            end)

            it("warns about macros that share a name", function()
                game.macros[2] = "Heal"
                game.bar[1] = { type = "macro", id = 1 }

                game:slash("save test")

                assert.are.same({
                    "Saved set 'test'!",
                    "Warning: Found 2 macros named 'Heal'. Consider renaming them to avoid issues",
                }, game:messages())
            end)

            it("requires a set name", function()
                game:slash("save")
                game:slash("restore")

                assert.are.same({ "Set name cannot be empty", "Set name cannot be empty" }, game:messages())
            end)

            it("reports a set that doesn't exist", function()
                game:slash("restore missing")

                assert.are.same({ "No set with the name 'missing' exists" }, game:messages())
            end)

            it("reports an action type it can't pick up, such as a flyout, and keeps going", function()
                game.bar[1] = { type = "flyout", id = 9 }
                game.bar[2] = { type = "spell", id = 100 }
                game:slash("save test")

                game:clearBar()
                game:clearOutput()
                game:slash("restore test")

                assert.are.same({ [2] = { type = "spell", id = 100 } }, game.bar)
                assert.are.same({
                    "Restored set 'test'",
                    "Error: Unable to restore flyout with id [9] to slot 1",
                }, game:messages())
            end)
        end)

        describe("alias groups", function()
            local function groups() return game.db.class.aliasGroups end

            it("restores another spell in the group, whichever one was saved", function()
                -- Troll and tauren racials: neither character can have the other's
                game:slash("alias spell racials 20554 20549")

                game.spells[20554] = "Berserking"
                game.bar[1] = { type = "spell", id = 20554 }
                game:slash("save troll")
                game.spells[20554] = nil
                game.bar[1] = { type = "spell", id = 20549 }
                game:slash("save tauren")

                game:clearBar()
                game:clearOutput()
                game:slash("restore troll")
                assert.are.same({ type = "spell", id = 20549 }, game.bar[1])

                game.spells[20554] = "Berserking"
                game.spells[20549] = nil
                game:clearBar()
                game:slash("restore tauren")
                assert.are.same({ type = "spell", id = 20554 }, game.bar[1])

                assert.are.same({
                    "Restored set 'troll'",
                    "Info: Restored spell 20549 (War Stomp) in place of spell 20554",
                    "Restored set 'tauren'",
                    "Info: Restored spell 20554 (Berserking) in place of spell 20549",
                }, game:messages())
            end)

            it("says the group was tried when nothing in it can be restored", function()
                game:slash("alias spell racials 20554 7744")
                game.bar[1] = { type = "spell", id = 20554 }
                game:slash("save test")

                game:clearBar()
                game:clearOutput()
                game:slash("restore test")

                assert.is_nil(game.bar[1])
                assert.are.same({
                    "Restored set 'test'",
                    "Error: Unable to restore spell 20554 or anything in its group 'racials' to slot 1",
                }, game:messages())
            end)

            it("restores items from an item group", function()
                game:slash("alias item hearth 6948 2")
                game.bar[1] = { type = "item", id = 2 }
                game:slash("save test")

                game:clearBar()
                game:clearOutput()
                game:slash("restore test")

                assert.are.same({ type = "item", id = 6948 }, game.bar[1])
                assert.are.same({
                    "Restored set 'test'",
                    "Info: Restored item 6948 in place of item 2",
                }, game:messages())
            end)

            it("only uses groups of the saved action's type", function()
                -- Item 20554 isn't spell 20554
                game:slash("alias spell racials 20554 20549")
                game.items[20554] = "Some Item"
                game.bar[1] = { type = "item", id = 20554 }
                game:slash("save test")

                game.items[20554] = nil
                game:clearBar()
                game:clearOutput()
                game:slash("restore test")

                assert.is_nil(game.bar[1])
                assert.are.same({
                    "Restored set 'test'",
                    "Error: Unable to restore item with id [20554] to slot 1",
                }, game:messages())
            end)

            if client.mountJournal then
                it("restores mounts from a mount group", function()
                    game:slash("alias mount wolves 1 2")
                    game.mounts = { 2 }
                    game.bar[1] = { type = "summonmount", id = 1 }
                    game:slash("save test")

                    game:clearBar()
                    game:slash("restore test")

                    assert.are.same({ type = "summonmount", id = 2 }, game.bar[1])
                    assert.are.same({ wolves = { 1, 2 } }, groups().summonmount)
                end)
            end

            it("adds to a group by name and lists groups by type", function()
                game:slash("alias spell Racials 20554 20549")
                game:slash("alias spell racials 7744 20549")
                game:slash("alias item hearth 6948")
                game:clearOutput()
                game:slash("aliases")

                assert.are.same({ racials = { 20554, 20549, 7744 } }, groups().spell)
                assert.are.same({
                    "spell 'racials': 20554, 20549 (War Stomp), 7744",
                    "item 'hearth': 6948",
                }, game:messages())
            end)

            it("keeps an ID in only one group per type", function()
                game:slash("alias spell racials 20554")
                game:slash("alias spell other 20554 100")

                assert.are.same({ racials = { 20554 }, other = { 100 } }, groups().spell)
                assert.are.same({
                    "Added spell 20554 to 'racials'",
                    "Can't add spell 20554 to 'other': it's already in 'racials'",
                    "Added spell 100 to 'other'",
                }, game:messages())
            end)

            it("removes IDs, and deletes a group once it's empty", function()
                game:slash("alias spell racials 20554 20549")
                game:clearOutput()
                game:slash("unalias spell racials 20549 7744")
                game:slash("unalias spell racials 20554")
                game:slash("aliases")

                assert.is_nil(groups().spell.racials)
                assert.are.same({
                    "Removed spell 20549 from 'racials'",
                    "'racials' doesn't have spell 7744",
                    "Removed spell 20554 from 'racials'",
                    "Group 'racials' is now empty and was deleted",
                    "No alias groups found",
                }, game:messages())
            end)

            it("deletes a whole group", function()
                game:slash("alias spell racials 20554 20549")
                game:clearOutput()
                game:slash("unalias spell racials")
                game:slash("unalias spell racials")

                assert.is_nil(groups().spell.racials)
                assert.are.same({
                    "Deleted spell group 'racials'",
                    "No spell group named 'racials'",
                }, game:messages())
            end)

            it("prints usage when the type, group or IDs are missing or wrong", function()
                local usage = "/abs alias <spell|item|mount> <group> <id> [id...] - e.g. /abs alias spell racials 20554 20549"
                game:slash("alias")
                game:slash("alias racials 20554")
                game:slash("alias spell")
                game:slash("alias spell racials")
                game:slash("alias spell racials stomp")
                game:slash("unalias racials")

                assert.are.same({}, groups())
                assert.are.same({
                    "Must provide a type: spell, item or mount", usage,
                    "Unknown type 'racials'. Must be spell, item or mount", usage,
                    "Must provide a group name", usage,
                    "Must provide at least one ID", usage,
                    "'stomp' is not an ID. IDs must be numbers", usage,
                    "Unknown type 'racials'. Must be spell, item or mount",
                    "/abs unalias <spell|item|mount> <group> [id...] - e.g. /abs unalias spell racials 20549",
                }, game:messages())
            end)

            it("drops aliases saved in the old format", function()
                game = wow.load(client, { class = { spellAliases = { [20554] = { 20549 } } } })

                assert.is_nil(game.db.class.spellAliases)
            end)
        end)

        describe("managing sets", function()
            it("lists sets alphabetically", function()
                game:slash("list")
                game:slash("save b")
                game:slash("save a")
                game:clearOutput()
                game:slash("list")

                assert.are.same({ "a, b" }, game:messages())
            end)

            it("deletes a set", function()
                game:slash("save test")
                game:slash("delete test")
                game:slash("delete test")

                assert.is_nil(sets().test)
                assert.are.same({
                    "Saved set 'test'!",
                    "Deleted set 'test'",
                    "No set with the name 'test' exists",
                }, game:messages())
            end)

            it("accepts commands in any case", function()
                game:slash("SAVE test")

                assert.is_not_nil(sets().test)
            end)

            it("prints usage for an unknown command", function()
                game:slash("bogus")

                assert.are.equal("ABS Slash commands", game:messages()[1])
            end)
        end)
    end)
end
