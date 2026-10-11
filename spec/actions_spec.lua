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
        local function aliases() return game.db.class.spellAliases end

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

        describe("spell aliases", function()
            it("restores an alias when the saved spell isn't known", function()
                -- e.g. a racial that has a different ID on another class
                game.spells[20554] = "Berserking"
                game.bar[1] = { type = "spell", id = 20554 }
                game:slash("save test")
                game:slash("alias 20554 20549")

                game.spells[20554] = nil
                game:clearBar()
                game:clearOutput()
                game:slash("restore test")

                assert.are.same({ type = "spell", id = 20549 }, game.bar[1])
                assert.are.same({
                    "Restored set 'test'",
                    "Info: Restored spell 20549 (War Stomp) in place of spell 20554",
                }, game:messages())
            end)

            it("adds, lists and removes aliases", function()
                game:slash("alias 20554 20549")
                game:slash("alias 20554 20549")
                game:slash("aliases")
                game:slash("unalias 20554")
                game:slash("aliases")

                assert.are.same({}, aliases())
                assert.are.same({
                    "Added 20549 as an alias for 20554",
                    "Spell 20554 is already aliased by 20549",
                    "Spell 20554 is aliased by: 20549",
                    "Removed all aliases for spell with ID 20554",
                    "No aliases found",
                }, game:messages())
            end)

            it("rejects alias arguments that aren't two spell IDs", function()
                game:slash("alias charge stomp")

                assert.are.same({}, aliases())
                assert.are.same({ "Could not parse spellID and aliasID from 'charge stomp'" }, game:messages())
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
